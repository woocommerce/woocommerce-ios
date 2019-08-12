import Foundation


/// Represents a Order's refund Entity.
///
public struct OrderRefund: Decodable {
    public let siteID: Int
    public let refundID: Int
    public let dateCreated: Date
    public let amount: String
    public let reason: String
    public let refunded_by: Int
    public let items: [OrderItem]
    
    /// If the refunded_payment field in this response is true, then we can assume that the refund was processed using automatic refund. If false, refund is processed manually.
    ///
    public let refunded_payment: Bool
    
    
    /// OrderRefund struct initializer.
    ///
    public init(siteID: Int,
                refundID: Int,
                dateCreated: Date,
                amount: String,
                reason: String,
                refunded_by: Int,
                items: [OrderItem],
                refunded_payment: Bool
        ) {
        self.siteID = siteID
        self.refundID = refundID
        self.dateCreated = dateCreated
        self.amount = amount
        self.reason = reason
        self.refunded_by = refunded_by
        self.items = items
        self.refunded_payment = refunded_payment
    }
    
    
    /// The public initializer for OrderRefund.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int else {
            throw OrderRefundDecodingError.missingSiteID
        }
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let refundID = try container.decode(Int.self, forKey: .refundID)
        let dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        let amount = try container.decode(String.self, forKey: .amount)
        let reason = try container.decode(String.self, forKey: .reason)
        let refunded_by = try container.decode(Int.self, forKey: .refunded_by)
        let items = try container.decode([OrderItem].self, forKey: .items)
        let refunded_payment = try container.decode(Bool.self, forKey: .refunded_payment)
        
        self.init(siteID: siteID,
                  refundID: refundID,
                  dateCreated: dateCreated,
                  amount: amount,
                  reason: reason,
                  refunded_by: refunded_by,
                  items: items,
                  refunded_payment: refunded_payment)
    }
}


/// Defines all of the OrderRefund CodingKeys
///
private extension OrderRefund {
    
    enum CodingKeys: String, CodingKey {
        case refundID           = "id"
        case dateCreated        = "date_created_gmt"
        case amount             = "amount"
        case reason             = "reason"
        case refunded_by        = "refunded_by"
        case items              = "line_items"
        case refunded_payment   = "refunded_payment"
    }
}


// MARK: - Comparable Conformance
//
extension OrderRefund: Comparable {
    public static func == (lhs: OrderRefund, rhs: OrderRefund) -> Bool {
        return lhs.siteID == rhs.siteID &&
            lhs.refundID == rhs.refundID &&
            lhs.dateCreated == rhs.dateCreated &&
            lhs.amount == rhs.amount &&
            lhs.reason == rhs.reason &&
            lhs.refunded_by == rhs.refunded_by &&
            lhs.items.count == rhs.items.count &&
            lhs.items.sorted() == rhs.items.sorted() &&
            lhs.refunded_payment == rhs.refunded_payment
    }
    
    public static func < (lhs: OrderRefund, rhs: OrderRefund) -> Bool {
        return lhs.refundID < rhs.refundID ||
            (lhs.refundID == rhs.refundID && lhs.dateCreated < rhs.dateCreated)
    }
}

// MARK: - Decoding Errors
//
enum OrderRefundDecodingError: Error {
    case missingSiteID
}
