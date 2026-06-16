import Foundation

/// Staff identifiers attached to a POS-originated WC REST request as `X-WC-POS-*` headers so the
/// order/refund/coupon timeline records which staff member acted.
///
/// - `actorUserID` is the staff member the action is attributed to: the operator for a normal
///   action, or the approving manager when a manager-override authorized it (override refunds).
/// - `initiatorUserID` records the cashier who started an override refund, when different from the
///   actor. It is `nil` for everything else.
///
/// Callers express "no attribution" by passing `nil` for the whole value rather than constructing
/// an instance with sentinel IDs. The headers are the single source of truth; nothing about POS
/// staff attribution goes in the request body.
public struct POSStaffAuth: Equatable, Sendable {
    public let actorUserID: Int64
    public let initiatorUserID: Int64?

    public init(actorUserID: Int64, initiatorUserID: Int64? = nil) {
        self.actorUserID = actorUserID
        self.initiatorUserID = initiatorUserID
    }

    public var headers: [String: String] {
        var headers = [
            "X-WC-POS-Request": "1",
            "X-WC-POS-Staff-Id": String(actorUserID)
        ]
        if let initiatorUserID {
            headers["X-WC-POS-Initiator-Id"] = String(initiatorUserID)
        }
        return headers
    }
}
