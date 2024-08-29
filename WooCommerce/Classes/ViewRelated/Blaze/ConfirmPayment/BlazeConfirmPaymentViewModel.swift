import Foundation
import Yosemite
import class Photos.PHAsset
import enum Networking.NetworkError
import protocol WooFoundation.Analytics

/// View model for `BlazeConfirmPaymentView`
final class BlazeConfirmPaymentViewModel: ObservableObject {

    private let productID: Int64
    private let siteID: Int64
    private let campaignInfo: CreateBlazeCampaign
    private let image: MediaPickerImage
    private let stores: StoresManager
    private let analytics: Analytics
    private let completionHandler: () -> Void

    private(set) var selectedPaymentMethod: BlazePaymentMethod? {
        didSet {
            displaySelectedPaymentMethodInfo()
        }
    }

    private var paymentInfo: BlazePaymentInfo?

    var shouldDisableCampaignCreation: Bool {
        isFetchingPaymentInfo || selectedPaymentMethod == nil
    }

    @Published var showAddPaymentSheet: Bool = false

    var paymentMethodsViewModel: BlazePaymentMethodsViewModel? {
        BlazePaymentMethodsViewModel(siteID: siteID,
                                     selectedPaymentMethodID: selectedPaymentMethod?.id,
                                     completion: { paymentID in
            Task { @MainActor [weak self] in
                guard let self else { return }
                showAddPaymentSheet = false

                if let existingPaymentMethod = paymentInfo?.paymentMethods.first(where: { $0.id == paymentID }) {
                    selectedPaymentMethod = existingPaymentMethod
                } else {
                    await updatePaymentInfo()
                    selectedPaymentMethod = paymentInfo?.paymentMethods.first(where: { $0.id == paymentID })
                }
            }
        })
    }

    var addPaymentWebViewModel: BlazeAddPaymentMethodWebViewModel? {
        return BlazeAddPaymentMethodWebViewModel(siteID: siteID) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }

                await updatePaymentInfo()
            }
        }
    }

    let totalAmount: String
    let totalAmountWithCurrency: String

    @Published private(set) var isFetchingPaymentInfo = false
    @Published private(set) var cardIcon: UIImage?
    @Published private(set) var cardTypeName: String?
    @Published private(set) var cardName: String?

    @Published var shouldDisplayPaymentErrorAlert = false
    @Published var campaignCreationError: BlazeCampaignCreationError? = nil

    @Published var isCreatingCampaign = false

    init(productID: Int64,
         siteID: Int64,
         campaignInfo: CreateBlazeCampaign,
         image: MediaPickerImage,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: @escaping () -> Void) {
        self.productID = productID
        self.siteID = siteID
        self.campaignInfo = campaignInfo
        self.image = image
        self.stores = stores
        self.analytics = analytics
        self.completionHandler = onCompletion

        let dayCountInWeek = BlazeBudgetSettingViewModel.Constants.dayCountInWeek
        let amount = campaignInfo.isEvergreen ? (campaignInfo.budget.amount * Double(dayCountInWeek)) : campaignInfo.budget.amount
        let formattedAmount = String(format: "$%.0f", amount)

        self.totalAmount = campaignInfo.isEvergreen ? String(format: Localization.totalWeeklyAmount, formattedAmount) : formattedAmount
        self.totalAmountWithCurrency = {
            if campaignInfo.isEvergreen {
                String(format: Localization.totalWeeklyAmountWithCurrency, formattedAmount, campaignInfo.budget.currency)
            } else {
                String(format: Localization.totalAmountWithCurrency, formattedAmount, campaignInfo.budget.currency)
            }
        }()
    }

    @MainActor
    func updatePaymentInfo() async {
        shouldDisplayPaymentErrorAlert = false
        isFetchingPaymentInfo = true
        do {
            let info = try await fetchPaymentInfo()
            paymentInfo = info
            selectedPaymentMethod = info.paymentMethods.first
        } catch {
            DDLogError("⛔️ Error fetching payment info for Blaze campaign creation: \(error)")
            shouldDisplayPaymentErrorAlert = true
        }
        isFetchingPaymentInfo = false
    }

    @MainActor
    func submitCampaign() async {
        guard let selectedPaymentMethod else {
            DDLogError("⚠️ No payment method found for campaign creation!")
            return
        }

        analytics.track(event: .Blaze.Payment.submitCampaignTapped())
        campaignCreationError = nil
        isCreatingCampaign = true
        do {
            // Prepare image for campaign
            let campaignMedia = try await prepareImage()

            // Set payment method ID, image URL and mimeType
            let updatedDetails = campaignInfo
                .copy(paymentMethodID: selectedPaymentMethod.id,
                      mainImage: .init(url: campaignMedia.src, mimeType: campaignMedia.mimeType))

            do {
                try await requestCampaignCreation(details: updatedDetails)
            } catch {
                DDLogError("⛔️ Error creating Blaze campaign: \(error)")
                if error.isInsuffientImageSizeError {
                    throw BlazeCampaignCreationError.insufficientImageSize
                } else {
                    throw BlazeCampaignCreationError.failedToCreateCampaign
                }
            }
            analytics.track(event: .Blaze.Payment.campaignCreationSuccess(isEvergreen: campaignInfo.isEvergreen))
            completionHandler()
        } catch {
            analytics.track(event: .Blaze.Payment.campaignCreationFailed(error: error))
            campaignCreationError = error as? BlazeCampaignCreationError ?? .failedToCreateCampaign
        }
        isCreatingCampaign = false
    }
}

private extension BlazeConfirmPaymentViewModel {
    func prepareImage() async throws -> Media {
        switch image.source {
        case .asset(let asset):
            do {
                return try await uploadPendingImage(asset)
            } catch {
                DDLogError("⛔️ Error uploading campaign image: \(error)")
                throw BlazeCampaignCreationError.failedToUploadCampaignImage
            }
        case .media(let media):
            return media
        case .productImage(let image):
            do {
                return try await retrieveMedia(mediaID: image.imageID)
            } catch {
                DDLogError("⛔️ Error fetching product image's Media: \(error)")
                throw BlazeCampaignCreationError.failedToFetchCampaignImage
            }
        }
    }

    @MainActor
    func fetchPaymentInfo() async throws -> BlazePaymentInfo {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(BlazeAction.fetchPaymentInfo(siteID: siteID, onCompletion: { result in
                continuation.resume(with: result)
            }))
        }
    }

    @MainActor
    func retrieveMedia(mediaID: Int64) async throws -> Media {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(MediaAction.retrieveMedia(siteID: siteID,
                                                      mediaID: mediaID,
                                                      onCompletion: { result in
                continuation.resume(with: result)
            }))
        }
    }

    @MainActor
    func uploadPendingImage(_ asset: PHAsset) async throws -> Media {
        func uploadAsset(_ asset: PHAsset) async throws -> Media {
            try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(MediaAction.uploadMedia(siteID: siteID,
                                                        productID: productID,
                                                        mediaAsset: asset,
                                                        altText: nil,
                                                        filename: nil,
                                                        onCompletion: { result in
                    continuation.resume(with: result)
                }))
            }
        }

        let media = try await {
            do {
                return try await uploadAsset(asset)
            } catch {
                // Try again as image upload request can fail due to network issues
                return try await uploadAsset(asset)
            }
        }()
        return media
    }

    @MainActor
    func requestCampaignCreation(details: CreateBlazeCampaign) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(BlazeAction.createCampaign(campaign: details, siteID: siteID, onCompletion: { result in
                continuation.resume(with: result)
            }))
        }
    }
}

private extension BlazeConfirmPaymentViewModel {
    func displaySelectedPaymentMethodInfo() {
        guard let paymentMethod = selectedPaymentMethod else {
            return
        }

        let rawCardType = paymentMethod.info.type
        let cardType = CreditCardType(rawType: rawCardType)
        cardIcon = cardType.icon
        cardTypeName = paymentMethod.info.type
        cardName = paymentMethod.name
    }
}

private extension BlazeConfirmPaymentViewModel {
    enum Localization {
        static let totalWeeklyAmount = NSLocalizedString(
            "blazeConfirmPaymentViewModel.totalWeeklyAmount",
            value: "%1$@ weekly",
            comment: "Total weekly amount of a Blaze campaign without an end date. " +
            "Reads as: $11 weekly"
        )
        static let totalWeeklyAmountWithCurrency = NSLocalizedString(
            "blazeConfirmPaymentViewModel.totalWeeklyAmountWithCurrency",
            value: "%1$@ %2$@ weekly",
            comment: "Total weekly amount of a Blaze campaign without an end date. " +
            "Placeholders are formatted amount and currency. " +
            "Reads as: $11 USD weekly"
        )
        static let totalAmountWithCurrency = NSLocalizedString(
            "blazeConfirmPaymentViewModel.totalAmountWithCurrency",
            value: "%1$@ %2$@",
            comment: "Total amount of a Blaze campaign. Placeholders are formatted amount and currency. " +
            "Reads as: $11 USD"
        )
    }
}

private extension Error {
    /// Error when campaign image size is not sufficient
    ///
    var isInsuffientImageSizeError: Bool {
        let errorCode = {
            if let error = self as? NetworkError, let code = error.responseCode {
                return code
            } else {
                return (self as NSError).code
            }
        }()
        return errorCode == 422
    }
}
