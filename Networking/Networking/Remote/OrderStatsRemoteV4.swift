import Foundation
import Alamofire

/// OrderStats: Remote Endpoints found in wc-admin's v4 API
///
public final class OrderStatsRemoteV4: Remote {
    /// Fetch the order stats for a given site, depending on the given granularity of the `unit` parameter.
    ///
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - unit: Defines the granularity of the stats we are fetching (one of 'hourly', 'daily', 'weekly', 'monthly', or 'yearly')
    ///   - latestDateToInclude: The latest date to include in the results.
    ///     This string is ISO8601 compliant
    ///   - completion: Closure to be executed upon completion.
    ///
    /// Note: by limiting the return values with the `_fields` param, we shrink the response size by over 90%! (~40kb to ~3kb)
    ///
    public func loadOrderStats(for siteID: Int,
                               unit: StatsGranularityV4,
                               latestDateToInclude: String,
                               quantity: Int,
                               completion: @escaping (OrderStatsV4?, Error?) -> Void) {
        let parameters = [ParameterKeys.interval: unit.rawValue,
                          ParameterKeys.before: latestDateToInclude,
                          ParameterKeys.quantity: String(quantity)]

        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: Constants.orderStatsPath, parameters: parameters)
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
        static let interval: String = "interval"
        static let before: String   = "before"
        static let quantity: String = "per_page"
        static let fields: String   = "_fields"
    }

    enum ParameterValues {
        static let fieldValues: String = """
            date,unit,quantity,fields,data,total_gross_sales,total_net_sales,total_orders,total_products,avg_gross_sales,avg_net_sales,avg_orders,avg_products
            """
    }
}
