import Foundation
import Yosemite

/// View model for `BlazeConfirmPaymentView`
final class BlazeConfirmPaymentViewModel: ObservableObject {

    private let siteID: Int64
    private let campaignInfo: CreateBlazeCampaign
    private let stores: StoresManager
    private let completionHandler: () -> Void

    private(set) var selectedPaymentMethod: BlazePaymentMethod?

    private var paymentInfo: BlazePaymentInfo?

    var shouldDisableCampaignCreation: Bool {
        isFetchingPaymentInfo || selectedPaymentMethod == nil
    }

    var paymentMethodsViewModel: BlazePaymentMethodsViewModel? {
        guard let paymentInfo else {
            DDLogError("⛔️ No payment info available to list in payment methods screen.")
            return nil
        }
        return BlazePaymentMethodsViewModel(siteID: siteID,
                                            paymentInfo: paymentInfo,
                                            selectedPaymentMethodID: selectedPaymentMethod?.id, completion: { paymentID in
            Task { [weak self] in
                guard let self else { return }
                await updatePaymentInfo()
                setSelectedPaymentMethod(id: paymentID)
            }
        })
    }

    let totalAmount: String

    @Published private(set) var isFetchingPaymentInfo = false
    @Published private(set) var cardIcon: UIImage?
    @Published private(set) var cardTypeName: String?
    @Published private(set) var cardName: String?

    @Published var shouldDisplayPaymentErrorAlert = false
    @Published var shouldDisplayCampaignCreationError = false

    @Published var isCreatingCampaign = false

    init(siteID: Int64,
         campaignInfo: CreateBlazeCampaign,
         stores: StoresManager = ServiceLocator.stores,
         onCompletion: @escaping () -> Void) {
        self.siteID = siteID
        self.campaignInfo = campaignInfo
        self.stores = stores
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
            if let firstPaymentMethod = info.savedPaymentMethods.first {
                setSelectedPaymentMethod(id: firstPaymentMethod.id)
            }
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
        shouldDisplayCampaignCreationError = false
        isCreatingCampaign = true
        do {
            let updatedDetails = campaignInfo.copy(paymentMethodID: selectedPaymentMethod.id)
            try await requestCampaignCreation(details: updatedDetails)
            completionHandler()
        } catch {
            DDLogError("⛔️ Error creating Blaze campaign: \(error)")
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

    func setSelectedPaymentMethod(id paymentMethodID: String) {
        guard let paymentMethod = paymentInfo?.savedPaymentMethods.first(where: { $0.id == paymentMethodID }) else {
            return
        }
        selectedPaymentMethod = paymentMethod
        let rawCardType = paymentMethod.info.type
        let cardType = CreditCardType(rawType: rawCardType)
        cardIcon = cardType.icon
        cardTypeName = paymentMethod.info.type
        cardName = paymentMethod.name
    }
}
