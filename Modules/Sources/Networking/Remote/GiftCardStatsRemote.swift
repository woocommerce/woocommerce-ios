import Foundation

/// Gift Card Stats: Remote Endpoints for fetching gift card stats.
///
public final class GiftCardStatsRemote: Remote {

    /// Fetch the used gift card stats for a given site, depending on the given granularity of the `unit` parameter.
    ///
    /// - Parameters:
    ///   - siteID: The site ID.
    ///   - unit: Defines the granularity of the stats we are fetching (one of 'hourly', 'daily', 'weekly', 'monthly', or 'yearly').
    ///   - timeZone: The time zone to set the earliest/latest date strings in the API request.
    ///   - earliestDateToInclude: The earliest date to include in the results.
    ///   - latestDateToInclude: The latest date to include in the results.
    ///   - quantity: The number of intervals to fetch.
    ///   - forceRefresh: Whether to enforce the data being refreshed.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadUsedGiftCardStats(for siteID: Int64,
                                      unit: StatsGranularityV4,
                                      timeZone: TimeZone,
                                      earliestDateToInclude: Date,
                                      latestDateToInclude: Date,
                                      quantity: Int,
                                      forceRefresh: Bool) async throws -> GiftCardStats {
        let dateFormatter = DateFormatter.Defaults.iso8601WithoutTimeZone
        dateFormatter.timeZone = timeZone

        var parameters: [String: Any] = [
            ParameterKeys.interval: unit.rawValue,
            ParameterKeys.after: dateFormatter.string(from: earliestDateToInclude),
            ParameterKeys.before: dateFormatter.string(from: latestDateToInclude),
            ParameterKeys.quantity: String(quantity)
        ]

        if forceRefresh {
            // includes this parameter only if it's true, otherwise the request fails
            parameters[ParameterKeys.forceRefresh] = forceRefresh
        }

        let request = JetpackRequest(wooApiVersion: .wcAnalytics,
                                     method: .get,
                                     siteID: siteID,
                                     path: Constants.giftCardsStatsPath,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = GiftCardStatsMapper(siteID: siteID, granularity: unit)

        return try await enqueue(request, mapper: mapper)
    }
}


// MARK: - Constants!
//
private extension GiftCardStatsRemote {
    enum Constants {
        static let giftCardsStatsPath: String = "reports/giftcards/used/stats"
    }

    enum ParameterKeys {
        static let interval     = "interval"
        static let after        = "after"
        static let before       = "before"
        static let quantity     = "per_page"
        static let forceRefresh = "force_cache_refresh"
    }
}
