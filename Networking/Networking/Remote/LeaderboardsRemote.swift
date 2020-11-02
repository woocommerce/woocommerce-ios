import Foundation


/// TopPerformersLeaderboard
///
public class LeaderboardsRemote: Remote {
    /// Fetch the leaderboards for a given site, depending on the given granularity of the `unit` parameter.
    ///
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - unit: Defines the granularity of the stats we are fetching (one of 'hour', 'day', 'week', 'month', or 'year')
    ///   - earliestDateToInclude: The earliest date to include in the results. This string is ISO8601 compliant
    ///   - latestDateToInclude: The latest date to include in the results. This string is ISO8601 compliant
    ///   - quantity: Number of resutls to fetch
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadLeaderboards(for siteID: Int64,
                                 unit: StatsGranularityV4,
                                 earliestDateToInclude: String,
                                 latestDateToInclude: String,
                                 quantity: Int,
                                 completion: @escaping (Result<[Leaderboard], Error>) -> Void) {
        let parameters = [ParameterKeys.interval: unit.rawValue,
                          ParameterKeys.after: earliestDateToInclude,
                          ParameterKeys.before: latestDateToInclude,
                          ParameterKeys.quantity: String(quantity)]

        let request = JetpackRequest(wooApiVersion: .wcAnalytics, method: .get, siteID: siteID, path: Constants.path, parameters: parameters)
        let mapper = LeaderboardListMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants
//
private extension LeaderboardsRemote {
    enum Constants {
        static let path = "leaderboards"
    }

    enum ParameterKeys {
        static let interval: String = "interval"
        static let after: String    = "after"
        static let before: String   = "before"
        static let quantity: String = "per_page"
    }
}
