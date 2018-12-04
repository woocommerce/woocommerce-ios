import Foundation
import Alamofire


/// Reports: Remote Endpoints
///
public class ReportRemote: Remote {
    /// Retrieves all of the order totals for a given site.
    ///
    /// *Note:* This is a Woo REST API v3 endpoint! It will not work on any Woo site under v3.5.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the order totals.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadOrderTotals(for siteID: Int, completion: @escaping ([OrderStatus: Int]?, Error?) -> Void) {
        let path = Constants.orderTotalsPath
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = ReportOrderTotalsMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }
}
// MARK: - Constants!
//
private extension ReportRemote {
    enum Constants {
        static let orderTotalsPath: String   = "reports/orders/totals"
    }
}
