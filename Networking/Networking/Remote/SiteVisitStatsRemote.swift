import Foundation
import Alamofire

/// SiteVisitStats: Remote Endpoints
///
public class SiteVisitStatsRemote: Remote {

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
                                     completion: @escaping (SiteVisitStats?, Error?) -> Void) {
        let path = "\(Constants.sitesPath)/\(siteID)/\(Constants.siteVisitStatsPath)/"
        let dateFormatter = DateFormatter.Stats.statsDayFormatter
        if let siteTimezone = siteTimezone {
            dateFormatter.timeZone = siteTimezone
        }
        let parameters = [ParameterKeys.unit: unit.rawValue,
                          ParameterKeys.date: dateFormatter.string(from: latestDateToInclude),
                          ParameterKeys.quantity: String(quantity),
                          ParameterKeys.statFields: Constants.visitorStatFieldValue]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        let mapper = SiteVisitStatsMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants!
//
private extension SiteVisitStatsRemote {
    enum Constants {
        static let sitesPath: String             = "sites"
        static let siteVisitStatsPath: String    = "stats/visits"
        static let visitorStatFieldValue: String = "visitors"
    }

    enum ParameterKeys {
        static let unit: String       = "unit"
        static let date: String       = "date"
        static let quantity: String   = "quantity"
        static let statFields: String = "stat_fields"
    }
}
