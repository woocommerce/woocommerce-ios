import Foundation
import Networking

// MARK: - AnalyticsStatsAction: Defines stats operations.
//
public enum AnalyticsStatsAction: Action {

    /// Clears all of the stats data.
    ///
    case resetStoredStats(onCompletion: () -> Void)

    /// Synchronizes `OrderStats` for the provided siteID, time range, and date.
    ///
    case retrieveStats(siteID: Int64,
        timeRange: AnalyticsRange,
        earliestDateToInclude: Date,
        latestDateToInclude: Date,
        quantity: Int,
        onCompletion: (Result<Void, Error>) -> Void)

    /// Synchronizes `SiteVisitStats` for the provided siteID, time range, and date.
    ///
    case retrieveSiteVisitStats(siteID: Int64,
        siteTimezone: TimeZone,
        timeRange: AnalyticsRange,
        latestDateToInclude: Date,
        onCompletion: (Result<Void, Error>) -> Void)

    /// Synchronizes `TopEarnerStats` for the provided siteID, time range, and date.
    ///
    case retrieveTopEarnerStats(siteID: Int64,
        timeRange: AnalyticsRange,
        earliestDateToInclude: Date,
        latestDateToInclude: Date,
        onCompletion: (Result<Void, Error>) -> Void)
}
