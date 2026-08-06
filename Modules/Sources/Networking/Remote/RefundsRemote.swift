import CocoaLumberjackSwift
import Foundation


/// The server-calculated refund endpoints (`/wc/v3` preview and `compute_totals` create,
/// WC 11.1.0+), abstracted for injection into `RefundService`.
///
public protocol RefundsRemoteProtocol {
    func previewRefund(for siteID: Int64,
                       orderID: Int64,
                       lineItems: [RefundPreviewLineItem]) async throws -> RefundPreview

    func createComputedRefund(for siteID: Int64,
                              orderID: Int64,
                              reason: String,
                              apiRefund: Bool,
                              apiRestock: Bool,
                              amount: String?,
                              lineItems: [ComputedRefundLineItem]) async throws -> Refund
}

/// Refunds: Remote Endpoints
///
public final class RefundsRemote: Remote, RefundsRemoteProtocol {

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
    // MARK: Server-calculated refund endpoints

    /// Previews a refund via `POST /wc/v3/orders/{orderID}/refunds/preview` (WC 11.1.0+),
    /// returning the server-calculated breakdown. On stores where the route is not registered the request
    /// fails with `DotcomError.noRestRoute` (404 `rest_no_route`) — the signal callers use to fall back
    /// to locally calculated refunds.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll preview a refund.
    ///     - orderID: Unique identifier for the order the refund is previewed against.
    ///     - lineItems: What to refund; the server computes all monetary values.
    ///
    public func previewRefund(for siteID: Int64,
                              orderID: Int64,
                              lineItems: [RefundPreviewLineItem]) async throws -> RefundPreview {
        let body = PreviewRefundBody(lineItems: lineItems)
        let path = "\(Path.orders)/\(orderID)/\(Path.refunds)/preview"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: try parameters(from: body),
                                     availableAsRESTRequest: true)
        return try await enqueue(request, mapper: SingleItemMapper<RefundPreview>(siteID: siteID))
    }

    /// Creates a refund with server-computed totals via `POST /wc/v3/orders/{orderID}/refunds`
    /// with `compute_totals: true` (WC 11.1.0+). Sends only *what* to refund; the server owns the math.
    ///
    /// SAFETY: on stores older than 11.1.0 the unknown `compute_totals` parameter is silently
    /// dropped and the request is handled by the classic v3 create, where a quantity-only body
    /// produces a ghost zero-amount refund with restock. Callers must never invoke this method
    /// unless a successful v3 preview has confirmed server-calculated refund support for the site.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll send a refund.
    ///     - orderID: Unique identifier for the order we're sending a refund for.
    ///     - reason: Optional merchant-facing reason for the refund.
    ///     - apiRefund: Whether the payment gateway should refund the payment (`api_refund`).
    ///       Always sent explicitly — the v3 endpoint defaults it to `true`.
    ///     - apiRestock: Whether refunded items are restocked (`api_restock`). Always sent
    ///       explicitly — the v3 endpoint defaults it to `true`.
    ///     - amount: Optional order-level total override. When omitted the server derives the
    ///       amount from the line items. POS always omits it — refund amount calculation is
    ///       delegated to the backend at create time, Interac card-present refunds included — so
    ///       this exists to mirror the endpoint's contract for any future caller that needs to pin
    ///       a total, not because the current flow uses it.
    ///     - lineItems: What to refund; the server computes all monetary values.
    ///
    public func createComputedRefund(for siteID: Int64,
                                     orderID: Int64,
                                     reason: String,
                                     apiRefund: Bool,
                                     apiRestock: Bool,
                                     amount: String?,
                                     lineItems: [ComputedRefundLineItem]) async throws -> Refund {
        let body = ComputedRefundBody(computeTotals: String(true),
                                      reason: reason,
                                      apiRefund: String(apiRefund),
                                      apiRestock: String(apiRestock),
                                      amount: amount,
                                      lineItems: lineItems)
        let path = "\(Path.orders)/\(orderID)/\(Path.refunds)"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: try parameters(from: body),
                                     availableAsRESTRequest: true)
        return try await enqueue(request, mapper: RefundMapper(siteID: siteID, orderID: orderID))
    }

    /// Serializes an encodable request body into the parameter dictionary `JetpackRequest` expects.
    ///
    private func parameters<Body: Encodable>(from body: Body) throws -> RequestParameterDictionary? {
        let encodedJson = try JSONEncoder().encode(body)
        return try (JSONSerialization.jsonObject(with: encodedJson, options: []) as? [String: Any])?.requestParameterDictionaryFromJSONObject()
    }
}

// MARK: - Server-calculated refund request bodies
//
private struct PreviewRefundBody: Encodable {
    let lineItems: [RefundPreviewLineItem]

    enum CodingKeys: String, CodingKey {
        case lineItems = "line_items"
    }
}

/// Stringified booleans follow the codebase's request-encoding convention; the v3 schema declares
/// `compute_totals`/`api_refund`/`api_restock` as booleans, so the REST layer sanitizes both forms.
private struct ComputedRefundBody: Encodable {
    let computeTotals: String
    let reason: String
    let apiRefund: String
    let apiRestock: String
    let amount: String?
    let lineItems: [ComputedRefundLineItem]

    // The synthesized conformance omits a nil `amount` (optionals encode via `encodeIfPresent`).
    enum CodingKeys: String, CodingKey {
        case computeTotals = "compute_totals"
        case reason
        case apiRefund = "api_refund"
        case apiRestock = "api_restock"
        case amount
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
