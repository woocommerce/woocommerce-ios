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
    ///   - quantity: Number of results to fetch
    ///   - forceRefresh: Whether to enforce the data being refreshed.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadLeaderboards(for siteID: Int64,
                                 unit: StatsGranularityV4,
                                 earliestDateToInclude: String,
                                 latestDateToInclude: String,
                                 quantity: Int,
                                 forceRefresh: Bool,
                                 completion: @escaping (Result<[Leaderboard], Error>) -> Void) {
        let parameters: [String: Any] = [
            ParameterKeys.interval: unit.rawValue,
            ParameterKeys.after: earliestDateToInclude,
            ParameterKeys.before: latestDateToInclude,
            ParameterKeys.quantity: String(quantity),
            ParameterKeys.forceRefresh: forceRefresh
        ]

        let request = JetpackRequest(wooApiVersion: .wcAnalytics,
                                     method: .get,
                                     siteID: siteID,
                                     path: Constants.path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = LeaderboardListMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Fetch the leaderboards with the deprecated API for a given site under WooCommerce version 6.7,
    /// depending on the given granularity of the `unit` parameter.
    ///
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - unit: Defines the granularity of the stats we are fetching (one of 'hour', 'day', 'week', 'month', or 'year')
    ///   - earliestDateToInclude: The earliest date to include in the results. This string is ISO8601 compliant
    ///   - latestDateToInclude: The latest date to include in the results. This string is ISO8601 compliant
    ///   - quantity: Number of results to fetch
    ///   - forceRefresh: Whether to enforce the data being refreshed
    ///   - completion: Closure to be executed upon completion
    ///
    public func loadLeaderboardsDeprecated(for siteID: Int64,
                                           unit: StatsGranularityV4,
                                           earliestDateToInclude: String,
                                           latestDateToInclude: String,
                                           quantity: Int,
                                           forceRefresh: Bool,
                                           completion: @escaping (Result<[Leaderboard], Error>) -> Void) {
        let parameters: [String: Any] = [
            ParameterKeys.interval: unit.rawValue,
            ParameterKeys.after: earliestDateToInclude,
            ParameterKeys.before: latestDateToInclude,
            ParameterKeys.quantity: String(quantity),
            ParameterKeys.forceRefresh: forceRefresh
        ]

        let request = JetpackRequest(wooApiVersion: .wcAnalytics,
                                     method: .get,
                                     siteID: siteID,
                                     path: Constants.pathDeprecated,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = LeaderboardListMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants
//
private extension LeaderboardsRemote {
    enum Constants {
        static let pathDeprecated = "leaderboards"
        static let path = "leaderboards/products"
    }

    enum ParameterKeys {
        static let interval = "interval"
        static let after = "after"
        static let before = "before"
        static let quantity = "per_page"
        static let forceRefresh = "force_cache_refresh"
    }
}
