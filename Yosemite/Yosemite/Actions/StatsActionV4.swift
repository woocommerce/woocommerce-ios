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
    case retrieveStats(siteID: Int64,
        timeRange: StatsTimeRangeV4,
        earliestDateToInclude: Date,
        latestDateToInclude: Date,
        quantity: Int,
        forceRefresh: Bool,
        onCompletion: (Result<Void, Error>) -> Void)

    /// Retrieves `OrderStats` for the provided siteID, and time range, without saving them to the Storage layer.
    ///
    case retrieveCustomStats(siteID: Int64,
                             unit: StatsGranularityV4,
                             earliestDateToInclude: Date,
                             latestDateToInclude: Date,
                             quantity: Int,
                             forceRefresh: Bool,
                             onCompletion: (Result<OrderStatsV4, Error>) -> Void)

    /// Synchronizes `SiteVisitStats` for the provided siteID, time range, and date.
    ///
    case retrieveSiteVisitStats(siteID: Int64,
        siteTimezone: TimeZone,
        timeRange: StatsTimeRangeV4,
        latestDateToInclude: Date,
        onCompletion: (Result<Void, Error>) -> Void)

    /// Retrieves `TopEarnerStats` for the provided siteID, time range, and date.
    /// Conditionally saves it to storage.
    ///
    case retrieveTopEarnerStats(siteID: Int64,
                                timeRange: StatsTimeRangeV4,
                                earliestDateToInclude: Date,
                                latestDateToInclude: Date,
                                quantity: Int,
                                forceRefresh: Bool,
                                saveInStorage: Bool,
                                onCompletion: (Result<TopEarnerStats, Error>) -> Void)

    /// Retrieves the site summary stats for the provided site ID, period(s), and date.
    /// Conditionally saves them to storage, if a single period is retrieved.
    ///
    case retrieveSiteSummaryStats(siteID: Int64,
                                  siteTimezone: TimeZone,
                                  period: StatGranularity,
                                  quantity: Int,
                                  latestDateToInclude: Date,
                                  saveInStorage: Bool,
                                  onCompletion: (Result<SiteSummaryStats, Error>) -> Void)
}
