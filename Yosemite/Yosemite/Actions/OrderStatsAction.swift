import Foundation
import Networking


// MARK: - OrderStatsAction: Defines all of the Actions supported by the OrderStatsStore.
//
public enum OrderStatsAction: Action {

    // FIXME: We are returning OrderStats in the completion handler...this needs to eventually return an error/nil much like
    // OrderAction.retrieveOrders. Update this once OrderStats storage is in place.
    case retrieveOrderStats(siteID: Int, granularity: OrderStatGranularity, latestDateToInclude: Date, quantity: Int, onCompletion: (OrderStats?, Error?) -> Void)
}
