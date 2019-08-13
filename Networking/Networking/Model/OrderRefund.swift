import Foundation


/// Represents a Order's refund Entity.
///
public struct OrderRefund: Decodable {
    public let siteID: Int
    public let refundID: Int
    public let dateCreated: Date
    public let amount: String
    public let reason: String
    public let refundedBy: Int
    public let items: [OrderItem]

    /// If the refundedPayment field in this response is true, then we can assume that the refund was processed using automatic refund. If false, refund is processed manually.
    ///
    public let refundedPayment: Bool


    /// OrderRefund struct initializer.
    ///
    public init(siteID: Int,
                refundID: Int,
                dateCreated: Date,
                amount: String,
                reason: String,
                refundedBy: Int,
                items: [OrderItem],
                refundedPayment: Bool
        ) {
        self.siteID = siteID
        self.refundID = refundID
        self.dateCreated = dateCreated
        self.amount = amount
        self.reason = reason
        self.refundedBy = refundedBy
        self.items = items
        self.refundedPayment = refundedPayment
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
        let refundedBy = try container.decode(Int.self, forKey: .refundedBy)
        let items = try container.decode([OrderItem].self, forKey: .items)
        let refundedPayment = try container.decode(Bool.self, forKey: .refundedPayment)

        self.init(siteID: siteID,
                  refundID: refundID,
                  dateCreated: dateCreated,
                  amount: amount,
                  reason: reason,
                  refundedBy: refundedBy,
                  items: items,
                  refundedPayment: refundedPayment)
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
        case refundedBy        = "refunded_by"
        case items              = "line_items"
        case refundedPayment   = "refunded_payment"
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
            lhs.refundedBy == rhs.refundedBy &&
            lhs.items.count == rhs.items.count &&
            lhs.items.sorted() == rhs.items.sorted() &&
            lhs.refundedPayment == rhs.refundedPayment
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
