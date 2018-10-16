import Foundation
import Networking


// MARK: - StatsAction: Defines stats operations (supported by the StatsStore).
//
public enum StatsAction: Action {
    case retrieveOrderStats(siteID: Int, granularity: StatGranularity, latestDateToInclude: Date, quantity: Int, onCompletion: (Error?) -> Void)
    case retrieveSiteVisitStats(siteID: Int, granularity: StatGranularity, latestDateToInclude: Date, quantity: Int, onCompletion: (Error?) -> Void)
    case retrieveTopEarnerStats(siteID: Int, granularity: StatGranularity, latestDateToInclude: Date, onCompletion: (Error?) -> Void)
}
