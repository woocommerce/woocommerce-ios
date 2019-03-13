import Foundation
import Alamofire


/// OrderStats: Remote Endpoints
///
public class OrderStatsRemote: Remote {

    /// Fetch the order stats for a given site up to the current day, week, month, or year (depending on the given granularity of the `unit` parameter).
    ///
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - unit: Defines the granularity of the stats we are fetching (one of 'day', 'week', 'month', or 'year')
    ///   - latestDateToInclude: The latest date to include in the results.
    ///     This string should match the `unit`, e.g.: 'day':'1955-11-05', 'week':'1955-W44', 'month':'1955-11', 'year':'1955'.
    ///   - quantity: How many `unit`s to fetch
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadOrderStats(for siteID: Int,
                               unit: StatGranularity,
                               latestDateToInclude: String,
                               quantity: Int,
                               completion: @escaping (OrderStats?, Error?) -> Void) {
        let path = "\(Constants.sitesPath)/\(siteID)/\(Constants.orderStatsPath)/"
        let parameters = [ParameterKeys.unit: unit.rawValue,
                          ParameterKeys.date: latestDateToInclude,
                          ParameterKeys.quantity: String(quantity)]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2, method: .get, path: path, parameters: parameters)
        let mapper = OrderStatsMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants!
//
private extension OrderStatsRemote {
    enum Constants {
        static let sitesPath: String        = "sites"
        static let orderStatsPath: String   = "stats/orders"
    }

    enum ParameterKeys {
        static let unit: String     = "unit"
        static let date: String     = "date"
        static let quantity: String = "quantity"
    }
}
