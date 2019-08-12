import Foundation
import Alamofire

/// Refunds: Remote Endpoints
///
public class RefundsRemote: Remote {

    /// Retrieves a specific list of `OrderRefunds`s by `orderID`.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote orders.
    ///     - orderID: Unique identifier for the resource "order" which you are searching
    ///                 for.
    ///     - context: view or edit. Scope under which the request is made;
    ///                determines fields present in response. Default is view.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of Orders to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadOrderRefunds(for siteID: Int,
                                 by orderID: Int,
                                 context: String = Default.context,
                                 pageNumber: Int = Default.pageNumber,
                                 pageSize: Int = Default.pageSize,
                                 completion: @escaping ([OrderRefund]?, Error?) -> Void) {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.contextKey: context
        ]
        let path = String(format: Path.orderRefunds, orderID)
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = OrderRefundsMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

}

// MARK: - Constants
//
public extension RefundsRemote {
    enum Default {
        public static let pageSize: Int   = 25
        public static let pageNumber: Int = 1
        public static let context: String = "view"
    }

    private enum Path {
        static let orderRefunds = "orders/%d/refunds"
    }

    private enum ParameterKey {
        static let page: String       = "page"
        static let perPage: String    = "per_page"
        static let contextKey: String = "context"
    }
}
