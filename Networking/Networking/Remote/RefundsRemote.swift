import Foundation
import Alamofire

/// Refunds: Remote Endpoints
///
public final class RefundsRemote: Remote {

    /// Retrieves all refunds for a specific `orderID`.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote order refunds.
    ///     - orderID: Unique identifier for the order we're searching for.
    ///     - context: view or edit. Scope under which the request is made;
    ///                determines fields present in response. Default is view.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of Refunds to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllRefunds(for siteID: Int,
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
        let path = "\(Path.orders)/" + String(orderID) + "/" + "\(Path.refunds)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = OrderRefundsMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves a single refund by refundID and orderID.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote order refunds.
    ///     - orderID: Unique identifier for the order we're searching for.
    ///     - refundID: Unique identifier for the refund we're searching for.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadRefund(siteID: Int,
                           orderID: Int,
                           refundID: Int,
                           completion: @escaping ([OrderRefund]?, Error?) -> Void) {
        let path = "\(Path.orders)/" + String(orderID) + "/" + "\(Path.refunds)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = OrderRefundsMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Create a refund by `orderID`.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll emit a refund.
    ///     - orderID: Unique identifier for the resource "order" for which you are emitting a refund.
    ///     - refund: The Refund model used to create the custom entity for the request.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func createRefund(for siteID: Int,
                                 by orderID: Int,
                                 refund: Refund,
                                 completion: @escaping (OrderRefund?, Error?) -> Void) {
        let path = "\(Path.orders)/" + String(orderID) + "/" + "\(Path.refunds)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: refund.toDictionary())
        let mapper = OrderRefundMapper(siteID: siteID)

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
        static let orders = "orders"
        static let refunds = "refunds"
    }

    private enum ParameterKey {
        static let page: String       = "page"
        static let perPage: String    = "per_page"
        static let contextKey: String = "context"
    }
}
