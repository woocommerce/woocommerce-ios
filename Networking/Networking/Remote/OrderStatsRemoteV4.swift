import Foundation

/// OrderStats: Remote Endpoints found in wc-admin's v4 API
///
public final class OrderStatsRemoteV4: Remote {
    /// Fetch the order stats for a given site, depending on the given granularity of the `unit` parameter.
    ///
    /// - Parameters:
    ///   - siteID: The site ID.
    ///   - unit: Defines the granularity of the stats we are fetching (one of 'hourly', 'daily', 'weekly', 'monthly', or 'yearly').
    ///   - timeZone: The time zone to set the earliest/latest date strings in the API request.
    ///   - earliestDateToInclude: The earliest date to include in the results.
    ///   - latestDateToInclude: The latest date to include in the results.
    ///   - quantity: The number of intervals to fetch the order stats.
    ///   - forceRefresh: Whether to enforce the data being refreshed.
    ///   - completion: Closure to be executed upon completion.
    ///
    /// Note: by limiting the return values with the `_fields` param, we shrink the response size by over 90%! (~40kb to ~3kb)
    ///
    public func loadOrderStats(for siteID: Int64,
                               unit: StatsGranularityV4,
                               timeZone: TimeZone,
                               earliestDateToInclude: Date,
                               latestDateToInclude: Date,
                               quantity: Int,
                               forceRefresh: Bool,
                               completion: @escaping (Result<OrderStatsV4, Error>) -> Void) {
        let dateFormatter = DateFormatter.Defaults.iso8601WithoutTimeZone
        dateFormatter.timeZone = timeZone

        var parameters: [String: Any] = [
            ParameterKeys.interval: unit.rawValue,
            ParameterKeys.after: dateFormatter.string(from: earliestDateToInclude),
            ParameterKeys.before: dateFormatter.string(from: latestDateToInclude),
            ParameterKeys.quantity: String(quantity),
            // Product stats in `ProductsReportsRemote.loadTopProductsReport` are based on the order creation date, while the order/revenue
            // stats are based on a store option in the analytics settings with the order paid date as the default.
            // In WC version 8.6+, a new parameter `date_type` is available to override the date type so that we can
            // show the order/revenue and product stats based on the same date column, order creation date.
            ParameterKeys.dateType: ParameterValues.dateType,
            ParameterKeys.fields: ParameterValues.fieldValues
        ]

        if forceRefresh {
            // includes this parameter only if it's true, otherwise the request fails
            parameters[ParameterKeys.forceRefresh] = forceRefresh
        }

        let request = JetpackRequest(wooApiVersion: .wcAnalytics,
                                     method: .get,
                                     siteID: siteID,
                                     path: Constants.orderStatsPath,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = OrderStatsV4Mapper(siteID: siteID, granularity: unit)
        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants!
//
private extension OrderStatsRemoteV4 {
    enum Constants {
        static let orderStatsPath: String = "reports/revenue/stats"
    }

    enum ParameterKeys {
        static let interval = "interval"
        static let after = "after"
        static let before = "before"
        static let quantity = "per_page"
        static let forceRefresh = "force_cache_refresh"
        static let dateType = "date_type"
        static let fields = "fields"
    }

    enum ParameterValues {
        static let dateType = "date_created"
        static let fieldValues = ["orders_count", "num_items_sold", "total_sales", "net_revenue", "avg_order_value"]
    }
}
