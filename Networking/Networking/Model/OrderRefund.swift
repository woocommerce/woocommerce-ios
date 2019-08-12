import Foundation


/// Represents a Order's refund Entity.
///
public struct OrderRefund: Decodable {
    public let refundID: Int
    public let reason: String
    public let total: String
    
    /// OrderRefund struct initializer.
    ///
    public init(refundID: Int,
                reason: String,
                total: String) {
        self.refundID = refundID
        self.reason = reason
        self.total = total
    }
    
    
    /// The public initializer for OrderRefund.
    ///
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let refundID = try container.decode(Int.self, forKey: .refundID)
        let reason = try container.decode(String.self, forKey: .reason)
        let total = try container.decode(String.self, forKey: .total)
        
        self.init(refundID: refundID,
                  reason: reason,
                  total: total)
    }
}


/// Defines all of the OrderRefund CodingKeys
///
private extension OrderRefund {
    
    enum CodingKeys: String, CodingKey {
        case refundID           = "id"
        case reason             = "reason"
        case total              = "total"
    }
}


// MARK: - Comparable Conformance
//
extension OrderRefund: Comparable {
    public static func == (lhs: OrderRefund, rhs: OrderRefund) -> Bool {
        return lhs.refundID == rhs.refundID &&
            lhs.reason == rhs.reason &&
            lhs.total == rhs.total
    }
    
    public static func < (lhs: OrderRefund, rhs: OrderRefund) -> Bool {
        return lhs.refundID < rhs.refundID
    }
}
