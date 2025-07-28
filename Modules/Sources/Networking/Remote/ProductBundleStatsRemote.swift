import Foundation

/// Product Bundle Stats: Remote Endpoints for fetching product bundle stats.
///
public final class ProductBundleStatsRemote: Remote {

    /// Fetch the product bundle stats for a given site, depending on the given granularity of the `unit` parameter.
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
    public func loadProductBundleStats(for siteID: Int64,
                                       unit: StatsGranularityV4,
                                       timeZone: TimeZone,
                                       earliestDateToInclude: Date,
                                       latestDateToInclude: Date,
                                       quantity: Int,
                                       forceRefresh: Bool) async throws -> ProductBundleStats {
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
                                     path: Constants.bundleStatsPath,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = ProductBundleStatsMapper(siteID: siteID, granularity: unit)

        return try await enqueue(request, mapper: mapper)
    }

    /// Fetch the top product bundles for a given site within the dates provided.
    ///
    /// - Parameters:
    ///   - siteID: The site ID.
    ///   - timeZone: The time zone to set the earliest/latest date strings in the API request.
    ///   - earliestDateToInclude: The earliest date to include in the results.
    ///   - latestDateToInclude: The latest date to include in the results.
    ///   - quantity: The number of bundles to fetch.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadTopProductBundlesReport(for siteID: Int64,
                                            timeZone: TimeZone,
                                            earliestDateToInclude: Date,
                                            latestDateToInclude: Date,
                                            quantity: Int) async throws -> [ProductsReportItem] {
        let dateFormatter = DateFormatter.Defaults.iso8601WithoutTimeZone
        dateFormatter.timeZone = timeZone

        let parameters: [String: Any] = [
            ParameterKeys.after: dateFormatter.string(from: earliestDateToInclude),
            ParameterKeys.before: dateFormatter.string(from: latestDateToInclude),
            ParameterKeys.quantity: String(quantity),
            ParameterKeys.orderBy: ParameterValues.orderBy,
            ParameterKeys.order: ParameterValues.order,
            ParameterKeys.extendedInfo: ParameterValues.extendedInfo
        ]

        let request = JetpackRequest(wooApiVersion: .wcAnalytics,
                                     method: .get,
                                     siteID: siteID,
                                     path: Constants.bundleReportsPath,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = ProductsReportMapper()

        return try await enqueue(request, mapper: mapper)
    }
}


// MARK: - Constants!
//
private extension ProductBundleStatsRemote {
    enum Constants {
        static let bundleStatsPath: String = "reports/bundles/stats"
        static let bundleReportsPath: String = "reports/bundles"
    }

    enum ParameterKeys {
        static let interval     = "interval"
        static let after        = "after"
        static let before       = "before"
        static let quantity     = "per_page"
        static let forceRefresh = "force_cache_refresh"
        static let orderBy      = "orderby"
        static let order        = "order"
        static let extendedInfo = "extended_info"
    }

    enum ParameterValues {
        static let orderBy      = "items_sold"
        static let order        = "desc"
        static let extendedInfo = "true"
    }
}
