import CocoaLumberjackSwift
import Foundation


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
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
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
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
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
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
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
            let parameters = try (JSONSerialization.jsonObject(with: encodedJson, options: []) as? [String: Any])?.requestParameterDictionaryFromJSONObject()
            let request = JetpackRequest(wooApiVersion: .mark3,
                                         method: .post,
                                         siteID: siteID,
                                         path: path,
                                         parameters: parameters,
                                         availableAsRESTRequest: true)

            enqueue(request, mapper: mapper) { result in
                switch result {
                case .success(let refund):
                    completion(refund, nil)
                case .failure(let error):
                    completion(nil, error)
                }
            }
        } catch {
            completion(nil, error)
            DDLogError("Unable to serialize data for refunds: \(error)")
        }
    }
    // MARK: v4 endpoints

    /// Previews a refund via `POST /wc/v4/refunds/preview` (WC 10.9.0+ behind the server `rest-api-v4` flag),
    /// returning the server-calculated breakdown. On stores where the route is not registered the request
    /// fails with `DotcomError.noRestRoute` (404 `rest_no_route`) — the signal callers use to fall back to v3.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll preview a refund.
    ///     - orderID: Unique identifier for the order the refund is previewed against.
    ///     - lineItems: What to refund; the server computes all monetary values.
    ///
    public func previewRefund(for siteID: Int64,
                              orderID: Int64,
                              lineItems: [RefundV4LineItem]) async throws -> RefundPreview {
        let body = PreviewRefundBody(orderID: orderID, lineItems: lineItems)
        let request = JetpackRequest(wooApiVersion: .mark4,
                                     method: .post,
                                     siteID: siteID,
                                     path: Path.refundsPreview,
                                     parameters: try parameters(from: body),
                                     availableAsRESTRequest: true)
        return try await enqueue(request, mapper: RefundPreviewMapper())
    }

    /// Creates a refund via the v4 simplified endpoint `POST /wc/v4/refunds` (WC 10.9.0+ behind the server
    /// `rest-api-v4` flag). Sends only *what* to refund — no client-calculated `amount`; the server owns the math.
    /// On stores where the route is not registered the request fails with `DotcomError.noRestRoute`.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll send a refund.
    ///     - orderID: Unique identifier for the order we're sending a refund for.
    ///     - reason: Optional merchant-facing reason for the refund.
    ///     - automaticRefund: Whether the payment gateway should refund the payment (`api_refund`).
    ///     - restockItems: Whether refunded items are restocked (`api_restock`). Always sent explicitly —
    ///       v4 defaults it to `false`, unlike v3's `restock_items`.
    ///     - lineItems: What to refund; the server computes all monetary values.
    ///
    public func createSimplifiedRefund(for siteID: Int64,
                                       orderID: Int64,
                                       reason: String,
                                       automaticRefund: Bool,
                                       restockItems: Bool,
                                       lineItems: [RefundV4LineItem]) async throws -> Refund {
        let body = SimplifiedRefundBody(orderID: orderID,
                                        reason: reason,
                                        apiRefund: String(automaticRefund),
                                        apiRestock: String(restockItems),
                                        lineItems: lineItems)
        let request = JetpackRequest(wooApiVersion: .mark4,
                                     method: .post,
                                     siteID: siteID,
                                     path: Path.refunds,
                                     parameters: try parameters(from: body),
                                     availableAsRESTRequest: true)
        return try await enqueue(request, mapper: SimplifiedRefundMapper(siteID: siteID, orderID: orderID))
    }

    /// Serializes an encodable request body into the parameter dictionary `JetpackRequest` expects.
    ///
    private func parameters<Body: Encodable>(from body: Body) throws -> RequestParameterDictionary? {
        let encodedJson = try JSONEncoder().encode(body)
        return try (JSONSerialization.jsonObject(with: encodedJson, options: []) as? [String: Any])?.requestParameterDictionaryFromJSONObject()
    }
}

// MARK: - v4 request bodies
//
private struct PreviewRefundBody: Encodable {
    let orderID: Int64
    let lineItems: [RefundV4LineItem]

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case lineItems = "line_items"
    }
}

private struct SimplifiedRefundBody: Encodable {
    let orderID: Int64
    let reason: String
    let apiRefund: String
    let apiRestock: String
    let lineItems: [RefundV4LineItem]

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case reason
        case apiRefund = "api_refund"
        case apiRestock = "api_restock"
        case lineItems = "line_items"
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
        static let refundsPreview = "refunds/preview"
    }

    private enum ParameterKey {
        static let page: String       = "page"
        static let perPage: String    = "per_page"
        static let contextKey: String = "context"
        static let include: String    = "include"
    }
}

extension RefundsRemote: POSRefundsRemoteProtocol {
    public func loadRefunds(for siteID: Int64, by orderID: Int64, with refundIDs: [Int64]) async throws -> [Refund] {
        return try await withCheckedThrowingContinuation { continuation in
            loadRefunds(for: siteID, by: orderID, with: refundIDs) { refunds, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: refunds ?? [])
                }
            }
        }
    }
}
