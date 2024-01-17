import Foundation
import Yosemite

/// View model for `BlazeConfirmPaymentView`
final class BlazeConfirmPaymentViewModel: ObservableObject {

    private let siteID: Int64
    private let campaignInfo: CreateBlazeCampaign
    private let stores: StoresManager

    let totalAmount: String

    init(siteID: Int64,
         campaignInfo: CreateBlazeCampaign,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.campaignInfo = campaignInfo
        self.stores = stores
        self.totalAmount = "$\(campaignInfo.totalBudget)"
    }
}
