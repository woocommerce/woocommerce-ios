import Foundation


/// Represents an Order Refund Entity.
///
public struct OrderRefundCondensed: Decodable {
    public let refundID: Int
    public let reason: String?
    public let total: String

    /// OrderRefundCondensed struct initializer
    ///
    public init(refundID: Int, reason: String?, total: String) {
        self.refundID = refundID
        self.reason = reason
        self.total = total
    }

    /// Public initializer for OrderRefundCondensed
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let refundID = try container.decode(Int.self, forKey: .refundID)
        let reason = try container.decodeIfPresent(String.self, forKey: .reason)
        let total = try container.decode(String.self, forKey: .total)

        // initialize the struct
        self.init(refundID: refundID, reason: reason, total: total)
    }
}


/// Defines all of the OrderRefundCondensed CodingKeys.
///
private extension OrderRefundCondensed {

    enum CodingKeys: String, CodingKey {
        case refundID   = "id"
        case reason     = "reason"
        case total      = "total"
    }
}

// MARK: - Comparable Conformance
//
extension OrderRefundCondensed: Comparable {
    public static func == (lhs: OrderRefundCondensed, rhs: OrderRefundCondensed) -> Bool {
        return lhs.refundID == rhs.refundID &&
            lhs.reason == rhs.reason &&
            lhs.total == rhs.total
    }

    public static func < (lhs: OrderRefundCondensed, rhs: OrderRefundCondensed) -> Bool {
        return lhs.refundID < rhs.refundID ||
            (lhs.refundID == rhs.refundID && lhs.total < rhs.total)
    }
}
