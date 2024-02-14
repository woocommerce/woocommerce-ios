import Foundation
import Yosemite
import class Photos.PHAsset

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
        guard let paymentInfo else {
            DDLogError("⛔️ No payment info available to list in payment methods screen.")
            return nil
        }
        return BlazePaymentMethodsViewModel(siteID: siteID,
                                            paymentInfo: paymentInfo,
                                            selectedPaymentMethodID: selectedPaymentMethod?.id,
                                            completion: { paymentID in
            Task { @MainActor [weak self] in
                guard let self else { return }
                showAddPaymentSheet = false

                if let existingPaymentMethod = paymentInfo.savedPaymentMethods.first(where: { $0.id == paymentID }) {
                    selectedPaymentMethod = existingPaymentMethod
                } else {
                    await updatePaymentInfo()
                    selectedPaymentMethod = paymentInfo.savedPaymentMethods.first(where: { $0.id == paymentID })
                }
            }
        })
    }

    var addPaymentWebViewModel: BlazeAddPaymentMethodWebViewModel? {
        guard let paymentInfo else {
            DDLogError("⛔️ No add payment info available to initiate Add payment method flow.")
            return nil
        }

        return BlazeAddPaymentMethodWebViewModel(siteID: siteID,
                                                 addPaymentMethodInfo: paymentInfo.addPaymentMethod) { [weak self] newPaymentMethodID in
            Task { @MainActor [weak self] in
                guard let self else { return }

                await updatePaymentInfo()
                selectedPaymentMethod = paymentInfo.savedPaymentMethods.first(where: { $0.id == newPaymentMethodID })
            }
        }
    }

    let totalAmount: String

    @Published private(set) var isFetchingPaymentInfo = false
    @Published private(set) var cardIcon: UIImage?
    @Published private(set) var cardTypeName: String?
    @Published private(set) var cardName: String?

    @Published var shouldDisplayPaymentErrorAlert = false
    @Published var shouldDisplayCampaignCreationError = false

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
        self.totalAmount = String(format: "$%.0f", campaignInfo.totalBudget)
    }

    @MainActor
    func updatePaymentInfo() async {
        shouldDisplayPaymentErrorAlert = false
        isFetchingPaymentInfo = true
        do {
            let info = try await fetchPaymentInfo()
            paymentInfo = info
            selectedPaymentMethod = info.savedPaymentMethods.first
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
        shouldDisplayCampaignCreationError = false
        isCreatingCampaign = true
        do {
            let updatedDetails = campaignInfo.copy(paymentMethodID: selectedPaymentMethod.id)
            try await requestCampaignCreation(details: updatedDetails)
            analytics.track(event: .Blaze.Payment.campaignCreationSuccess())
            completionHandler()
        } catch {
            DDLogError("⛔️ Error creating Blaze campaign: \(error)")
            analytics.track(event: .Blaze.Payment.campaignCreationFailed())
            shouldDisplayCampaignCreationError = true
        }
        isCreatingCampaign = false
    }
}

private extension BlazeConfirmPaymentViewModel {
    @MainActor
    func fetchPaymentInfo() async throws -> BlazePaymentInfo {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(BlazeAction.fetchPaymentInfo(siteID: siteID, onCompletion: { result in
                continuation.resume(with: result)
            }))
        }
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
