import Foundation


/// Refunds: Remote Endpoints
///
public final class RefundsRemote: Remote {

    /// Retrieves all of the `Refund`s available for a given Order ID.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote refunds.
    ///     - orderID: Order for which we'll fetch remote refunds.
    ///     - context: view or edit. Scope under which the request is made;
    ///                determines fields present in response. Default is view.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of models to be retrieved per page.
    /// - Returns: Array of refunds.
    /// - Throws: Error if the request fails.
    ///
    public func loadAllRefunds(for siteID: Int64,
                               by orderID: Int64,
                               context: String = Default.context,
                               pageNumber: Int = Default.pageNumber,
                               pageSize: Int = Default.pageSize) async throws -> [Refund] {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.contextKey: context
        ]
        let path = "\(Path.orders)/" + String(orderID) + "/" + "\(Path.refunds)"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = RefundListMapper(siteID: siteID, orderID: orderID)

        return try await enqueue(request, mapper: mapper)
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
    /// - Returns: Array of refunds.
    /// - Throws: Error if the request fails.
    ///
    public func loadRefunds(for siteID: Int64, by orderID: Int64, with refundIDs: [Int64]) async throws -> [Refund] {
        let stringOfRefundIDs = refundIDs.sortedUniqueIntToString()
        let parameters = [ ParameterKey.include: stringOfRefundIDs ]
        let path = "\(Path.orders)/" + String(orderID) + "/" + "\(Path.refunds)"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = RefundListMapper(siteID: siteID, orderID: orderID)

        return try await enqueue(request, mapper: mapper)
    }

    /// Retrieves a single refund by refundID and orderID.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote order refunds.
    ///     - orderID: Unique identifier for the order we're searching for.
    ///     - refundID: Unique identifier for the refund we're searching for.
    /// - Returns: The requested refund.
    /// - Throws: Error if the request fails.
    ///
    public func loadRefund(siteID: Int64,
                           orderID: Int64,
                           refundID: Int64) async throws -> Refund {
        let path = Path.orders + "/" + String(orderID) + "/" + Path.refunds + "/" + String(refundID)
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
        let mapper = RefundMapper(siteID: siteID, orderID: orderID)

        return try await enqueue(request, mapper: mapper)
    }

    /// Create a refund by `orderID`.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll send a refund.
    ///     - orderID: Unique identifier for the order we're sending a refund for.
    ///     - refund: The Refund model used to create the custom entity for the request.
    /// - Returns: The created refund.
    /// - Throws: Error if the request fails.
    ///
    public func createRefund(for siteID: Int64,
                             by orderID: Int64,
                             refund: Refund) async throws -> Refund {
        let path = "\(Path.orders)/" + String(orderID) + "/" + "\(Path.refunds)"
        let mapper = RefundMapper(siteID: siteID, orderID: orderID)

        do {
            let encodedJson = try mapper.map(refund: refund)
            let parameters: [String: Any]? = try JSONSerialization.jsonObject(with: encodedJson, options: []) as? [String: Any]
            let request = JetpackRequest(wooApiVersion: .mark3,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters,
                                         availableAsRESTRequest: true)

            return try await enqueue(request, mapper: mapper)
        } catch {
            DDLogError("Unable to serialize data for refunds: \(error)")
            throw error
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
