import Foundation

/// Protocol for requesting manager approval via the backend REST API.
/// The concrete networking implementation lives in the app target (bridged via adaptor).
public protocol POSApprovalServiceProtocol: Sendable {
    /// Requests manager approval for a restricted action.
    /// - Parameters:
    ///   - pin: The manager's PIN.
    ///   - action: The capability or action being approved (e.g. "woocommerce_refund_orders").
    ///   - context: Additional context for the approval (e.g. ["order_id": 123]).
    /// - Returns: An approval token string on success.
    func requestApproval(pin: String, action: String, context: [String: Int64]) async throws -> String
}
