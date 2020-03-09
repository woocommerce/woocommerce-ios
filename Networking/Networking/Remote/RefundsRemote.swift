import Foundation
import Alamofire


/// Refunds: Remote Endpoints
///
public final class RefundsRemote: Remote {

    /// Retrieves all `Refunds` available for a specific `orderID`.
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
    public func loadAllRefunds(for siteID: Int64,
                               by orderID: Int64,
                               context: String = Default.context,
                               pageNumber: Int = Default.pageNumber,
                               pageSize: Int = Default.pageSize,
                               completion: @escaping ([Refund]?, Error?) -> Void) {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.contextKey: context
        ]
        let path = "\(Path.orders)/" + String(orderID) + "/" + "\(Path.refunds)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = RefundListMapper(siteID: siteID, orderID: orderID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves a specific list of `Refund`s by `refundID`.
    ///
    /// - Note: this method makes a single request for a list of refunds.
    ///         It is NOT a wrapper for `loadRefund()`
    ///
    /// - Parameters:
    ///     - siteID: We are fetching remote refunds for this site.
    ///     - orderID: We are fetching remote refunds for this order.
    ///     - refundIDs: The array of refund IDs that are requested.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadRefunds(for siteID: Int64, by orderID: Int64, with refundIDs: [Int64], completion: @escaping ([Refund]?, Error?) -> Void) {
        let stringOfRefundIDs = refundIDs.sortedUniqueIntToString()
        let parameters = [ ParameterKey.include: stringOfRefundIDs ]
        let path = "\(Path.orders)/" + String(orderID) + "/" + "\(Path.refunds)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = RefundListMapper(siteID: siteID, orderID: orderID)

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
    public func loadRefund(siteID: Int64,
                           orderID: Int64,
                           refundID: Int64,
                           completion: @escaping (Refund?, Error?) -> Void) {
        let path = Path.orders + "/" + String(orderID) + "/" + Path.refunds + "/" + String(refundID)
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = RefundMapper(siteID: siteID, orderID: orderID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Create a refund by `orderID`.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll send a refund.
    ///     - orderID: Unique identifier for the order we're sending a refund for.
    ///     - refund: The Refund model used to create the custom entity for the request.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func createRefund(for siteID: Int64,
                             by orderID: Int64,
                             refund: Refund,
                             completion: @escaping (Refund?, Error?) -> Void) {
        let path = "\(Path.orders)/" + String(orderID) + "/" + "\(Path.refunds)"
        let mapper = RefundMapper(siteID: siteID, orderID: orderID)

        do {
            let encodedJson = try mapper.map(refund: refund)
            let parameters: [String: Any]? = try JSONSerialization.jsonObject(with: encodedJson, options: []) as? [String: Any]
            let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters)

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(nil, error)
            DDLogError("Unable to serialize data for refunds: \(error)")
        }
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
        static let orders   = "orders"
        static let refunds  = "refunds"
    }

    private enum ParameterKey {
        static let page: String       = "page"
        static let perPage: String    = "per_page"
        static let contextKey: String = "context"
        static let include: String    = "include"
    }
}
