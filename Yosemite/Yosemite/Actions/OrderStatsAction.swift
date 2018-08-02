import Foundation
import Networking


// MARK: - OrderStatsAction: Defines all of the Actions supported by the OrderStatsStore.
//
public enum OrderStatsAction: Action {
    case retrieveOrderStats(siteID: Int, granularity: OrderStatGranularity, latestDateToInclude: Date, quantity: Int, onCompletion: (OrderStats?, Error?) -> Void)
}
