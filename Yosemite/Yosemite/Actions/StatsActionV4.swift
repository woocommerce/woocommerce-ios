import Foundation
import Networking

// MARK: - StatsActionV4: Defines stats operations (supported by the StatsStoreV4).
//
public enum StatsActionV4: Action {

    /// Clears all of the stats data.
    ///
    case resetStoredStats(onCompletion: () -> Void)

    /// Synchronizes `OrderStats` for the provided siteID, time range, and date.
    ///
    case retrieveStats(siteID: Int,
        timeRange: StatsTimeRangeV4,
        earliestDateToInclude: Date,
        latestDateToInclude: Date,
        quantity: Int,
        onCompletion: (Error?) -> Void)

    /// Synchronizes `SiteVisitStats` for the provided siteID, time range, and date.
    ///
    case retrieveSiteVisitStats(siteID: Int,
        siteTimezone: TimeZone,
        timeRange: StatsTimeRangeV4,
        latestDateToInclude: Date,
        onCompletion: (Error?) -> Void)

    /// Synchronizes `TopEarnerStats` for the provided siteID, time range, and date.
    ///
    case retrieveTopEarnerStats(siteID: Int,
        timeRange: StatsTimeRangeV4,
        latestDateToInclude: Date,
        onCompletion: (Error?) -> Void)
}
