import Foundation
import Yosemite

/// View model for `BlazeConfirmPaymentView`
final class BlazeConfirmPaymentViewModel: ObservableObject {

    private let siteID: Int64
    private let campaignInfo: CreateBlazeCampaign
    private let stores: StoresManager

    private(set) var selectedPaymentMethod: BlazePaymentMethod?

    let totalAmount: String

    @Published private(set) var isFetchingPaymentInfo = false
    @Published private(set) var cardIcon: UIImage?
    @Published private(set) var cardTypeName: String?
    @Published private(set) var cardName: String?
    @Published private(set) var fetchError: Error?

    init(siteID: Int64,
         campaignInfo: CreateBlazeCampaign,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.campaignInfo = campaignInfo
        self.stores = stores
        self.totalAmount = "$\(campaignInfo.totalBudget)"
    }

    @MainActor
    func updatePaymentInfo() async {
        fetchError = nil
        isFetchingPaymentInfo = true
        do {
            let info = try await fetchPaymentInfo()
            selectedPaymentMethod = info.savedPaymentMethods.first
            if let selectedPaymentMethod {
                let rawCardType = selectedPaymentMethod.info.type
                let cardType = CreditCardType(rawType: rawCardType)
                cardIcon = cardType.icon
                cardTypeName = selectedPaymentMethod.info.type
                cardName = selectedPaymentMethod.name
            }
        } catch {
            DDLogError("⛔️ Error fetching payment info for Blaze campaign creation: \(error)")
            fetchError = error
        }
        isFetchingPaymentInfo = false
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
}
