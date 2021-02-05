import Foundation
import Alamofire


/// TopEarnersStats: Remote Endpoints
///
public class TopEarnersStatsRemote: Remote {

    /// Fetch the top earner (aka Top Performer) stats for a given site for the current day, week, month, or year
    /// (depends on the given granularity of the `unit` parameter).
    ///
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - unit: Defines the granularity of the stats we are fetching (one of 'day', 'week', 'month', or 'year')
    ///   - latestDateToInclude: The latest date to include in the results (see Note below)
    ///   - limit: Maximum number of `unit`s to fetch
    ///   - completion: Closure to be executed upon completion.
    ///
    /// Note: `latestDateToInclude` string must be formatted appropriately given the `unit` param. See: `DateFormatter.Stats` extension for some helper funcs.
    ///
    public func loadTopEarnersStats(for siteID: Int64,
                                    unit: StatGranularity,
                                    latestDateToInclude: String,
                                    limit: Int,
                                    completion: @escaping (TopEarnerStats?, Error?) -> Void) {
        let path = "\(Constants.sitesPath)/\(siteID)/\(Constants.topEarnersStatsPath)/"
        let parameters = [ParameterKeys.unit: unit.rawValue,
                          ParameterKeys.date: latestDateToInclude,
                          ParameterKeys.limit: String(limit)]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path, parameters: parameters)
        let mapper = TopEarnerStatsMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants!
//
private extension TopEarnersStatsRemote {
    enum Constants {
        static let sitesPath: String            = "sites"
        static let topEarnersStatsPath: String  = "stats/top-earners"
    }

    enum ParameterKeys {
        static let unit: String     = "unit"
        static let date: String     = "date"
        static let limit: String    = "limit"
    }
}
