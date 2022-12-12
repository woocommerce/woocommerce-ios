import Foundation

/// SiteStats: Remote Endpoints
///
public class SiteStatsRemote: Remote {

    /// Fetch the visitor stats for a given site up to the current day, week, month, or year (depending on the given granularity of the `unit` parameter).
    ///
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - unit: Defines the granularity of the stats we are fetching (one of 'day', 'week', 'month', or 'year')
    ///   - latestDateToInclude: The latest date to include in the results.
    ///   - quantity: How many `unit`s to fetch
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadSiteVisitorStats(for siteID: Int64,
                                     siteTimezone: TimeZone? = nil,
                                     unit: StatGranularity,
                                     latestDateToInclude: Date,
                                     quantity: Int,
                                     completion: @escaping (Result<SiteVisitStats, Error>) -> Void) {
        let path = "\(Path.sites)/\(siteID)/\(Path.siteVisitStats)/"
        let dateFormatter = DateFormatter.Stats.statsDayFormatter
        if let siteTimezone = siteTimezone {
            dateFormatter.timeZone = siteTimezone
        }
        let parameters = [ParameterKeys.unit: unit.rawValue,
                          ParameterKeys.date: dateFormatter.string(from: latestDateToInclude),
                          ParameterKeys.quantity: String(quantity),
                          ParameterKeys.statFields: "\(ParameterValues.visitors),\(ParameterValues.views)"]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        let mapper = SiteVisitStatsMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants!
//
private extension SiteStatsRemote {
    enum Path {
        static let sites: String             = "sites"
        static let siteVisitStats: String    = "stats/visits"
    }

    enum ParameterKeys {
        static let unit: String       = "unit"
        static let date: String       = "date"
        static let quantity: String   = "quantity"
        static let statFields: String = "stat_fields"
    }

    enum ParameterValues {
        static let visitors: String = "visitors"
        static let views: String    = "views"
    }
}
