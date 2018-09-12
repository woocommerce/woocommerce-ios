import Foundation
import Networking


// MARK: - StatsAction: Defines stats operations (supported by the StatsStore).
//
public enum StatsAction: Action {

    // FIXME: We are returning OrderStats in the completion handler...this needs to eventually return an error/nil much like OrderAction.retrieveOrders. Update this once OrderStats storage is in place.
    case retrieveOrderStats(siteID: Int, granularity: StatGranularity, latestDateToInclude: Date, quantity: Int, onCompletion: (OrderStats?, Error?) -> Void)

    // FIXME: We are returning SiteVisitStats in the completion handler...this needs to eventually return an error/nil much like OrderAction.retrieveOrders. Update this once SiteVisitStats storage is in place.
    case retrieveSiteVisitStats(siteID: Int, granularity: StatGranularity, latestDateToInclude: Date, quantity: Int, onCompletion: (SiteVisitStats?, Error?) -> Void)

    case retrieveTopEarnerStats(siteID: Int, granularity: StatGranularity, latestDateToInclude: Date, onCompletion: (Error?) -> Void)
}
