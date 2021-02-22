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
    ///   - completion: Closure to be executed upon completion.
    ///
    /// Note: by limiting the return values with the `_fields` param, we shrink the response size by over 90%! (~40kb to ~3kb)
    ///
    public func loadOrderStats(for siteID: Int64,
                               unit: StatsGranularityV4,
                               earliestDateToInclude: Date,
                               latestDateToInclude: Date,
                               quantity: Int,
                               completion: @escaping (OrderStatsV4?, Error?) -> Void) {
        let dateFormatter = DateFormatter.Defaults.iso8601WithoutTimeZone

        // Workaround for #1183: random number between 31-100 for `num_page` param.
        // Replace `randomQuantity` with `quantity` in `num_page` param when API issue is fixed.
        let randomQuantity = arc4random_uniform(70) + 31

        let parameters = [ParameterKeys.interval: unit.rawValue,
                          ParameterKeys.after: dateFormatter.string(from: earliestDateToInclude),
                          ParameterKeys.before: dateFormatter.string(from: latestDateToInclude),
                          ParameterKeys.quantity: String(randomQuantity)]

        let request = JetpackRequest(wooApiVersion: .wcAnalytics, method: .get, siteID: siteID, path: Constants.orderStatsPath, parameters: parameters)
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
        static let after: String    = "after"
        static let before: String   = "before"
        static let quantity: String = "per_page"
    }
}
