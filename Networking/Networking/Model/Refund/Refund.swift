import Foundation


/// Represents a Refund Entity.
///
public struct Refund: Codable {
    public let siteID: Int
    public let refundID: Int
    public let dateCreated: Date   // in gmt
    public let amount: String
    public let reason: String?
    public let refundedByUserID: Int
    public let items: [OrderItemRefund]

    /// If the refunded payment field in this response is true,
    /// then we can assume that the refund was processed using automatic refund.
    /// If false, the refund is processed manually.
    ///
    public let automaticGatewayRefund: Bool?


    /// OrderRefund struct initializer.
    ///
    public init(siteID: Int,
                refundID: Int,
                dateCreated: Date,
                amount: String,
                reason: String?,
                refundedByUserID: Int,
                items: [OrderItemRefund],
                automaticGatewayRefund: Bool?
        ) {
        self.siteID = siteID
        self.refundID = refundID
        self.dateCreated = dateCreated
        self.amount = amount
        self.reason = reason
        self.refundedByUserID = refundedByUserID
        self.items = items
        self.automaticGatewayRefund = automaticGatewayRefund
    }


    /// The public initializer for Refund.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int else {
            throw OrderRefundDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let refundID = try container.decode(Int.self, forKey: .refundID)
        let dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        let amount = try container.decode(String.self, forKey: .amount)
        let reason = try container.decodeIfPresent(String.self, forKey: .reason)
        let refundedByUserID = try container.decode(Int.self, forKey: .refundedByUserID)
        let items = try container.decode([OrderItemRefund].self, forKey: .items)
        let automaticGatewayRefund = try container.decodeIfPresent(Bool.self, forKey: .automaticGatewayRefund)

        self.init(siteID: siteID,
                  refundID: refundID,
                  dateCreated: dateCreated,
                  amount: amount,
                  reason: reason,
                  refundedByUserID: refundedByUserID,
                  items: items,
                  automaticGatewayRefund: automaticGatewayRefund)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(refundID, forKey: .refundID)
        try container.encode(dateCreated, forKey: .dateCreated)
        try container.encode(amount, forKey: .amount)
        try container.encode(reason, forKey: .reason)
        try container.encode(refundedByUserID, forKey: .refundedByUserID)
        try container.encode(items, forKey: .items)
        try container.encode(automaticGatewayRefund, forKey: .automaticGatewayRefund)
    }
}


/// Defines all of the Refund CodingKeys
///
private extension Refund {

    enum CodingKeys: String, CodingKey {
        case refundID                   = "id"
        case dateCreated                = "date_created_gmt"
        case amount                     = "amount"
        case reason                     = "reason"
        case refundedByUserID           = "refunded_by"
        case items                      = "line_items"
        case automaticGatewayRefund     = "refunded_payment"
    }
}


// MARK: - Comparable Conformance
//
extension Refund: Comparable {
    public static func == (lhs: Refund, rhs: Refund) -> Bool {
        return lhs.siteID == rhs.siteID &&
            lhs.refundID == rhs.refundID &&
            lhs.dateCreated == rhs.dateCreated &&
            lhs.amount == rhs.amount &&
            lhs.reason == rhs.reason &&
            lhs.refundedByUserID == rhs.refundedByUserID &&
            lhs.items.count == rhs.items.count &&
            lhs.items.sorted() == rhs.items.sorted() &&
            lhs.automaticGatewayRefund == rhs.automaticGatewayRefund
    }

    public static func < (lhs: Refund, rhs: Refund) -> Bool {
        return lhs.refundID == rhs.refundID && lhs.dateCreated < rhs.dateCreated
    }
}

// MARK: - Decoding Errors
//
enum RefundDecodingError: Error {
    case missingSiteID
}
