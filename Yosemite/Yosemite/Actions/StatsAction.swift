import Foundation
import Networking


// MARK: - StatsAction: Defines stats operations (supported by the StatsStore).
//
public enum StatsAction: Action {

    /// Synchronizes `OrderStats` for the provided siteID, StatGranularity, and date.
    ///
    case retrieveOrderStats(siteID: Int, granularity: StatGranularity, latestDateToInclude: Date, quantity: Int, onCompletion: (Error?) -> Void)

    /// Synchronizes `SiteVisitStats` for the provided siteID, StatGranularity, and date.
    ///
    case retrieveSiteVisitStats(siteID: Int, granularity: StatGranularity, latestDateToInclude: Date, quantity: Int, onCompletion: (Error?) -> Void)

    /// Synchronizes `TopEarnerStats` for the provided siteID, `StatGranularity`, and date.
    ///
    case retrieveTopEarnerStats(siteID: Int, granularity: StatGranularity, latestDateToInclude: Date, onCompletion: (Error?) -> Void)

    /// Retrieves the current order count for a specifc `OrderStatus` from the server. By design, the server response is *not*
    /// persisted in the Storage framework but is instead returned within the completion closure.
    ///
    case retrieveOrderTotals(siteID: Int, status: OrderStatus, onCompletion: (Int?, Error?) -> Void)
}
