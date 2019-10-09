import Foundation


/// Represents a decoded Refund entity.
///
public struct Refund: Decodable {
    public let refundID: Int
    public let orderID: Int
    public let dateCreated: Date // gmt
    public let amount: String
    public let reason: String
    public let refundedByUserID: Int

    /// If true, the automatic refund is used.
    /// When false, manual refund process is used.
    ///
    public let isAutomatedRefund: Bool

    public let items: [OrderItemRefund]

    /// Refund struct initializer
    ///
    public init(refundID: Int,
                orderID: Int,
                dateCreated: Date,
                amount: String,
                reason: String,
                refundedByUserID: Int,
                isAutomatedRefund: Bool,
                items: [OrderItemRefund]) {
        self.refundID = refundID
        self.orderID = orderID
        self.dateCreated = dateCreated
        self.amount = amount
        self.reason = reason
        self.refundedByUserID = refundedByUserID
        self.isAutomatedRefund = isAutomatedRefund
        self.items = items
    }

    // The public initializer for a Refund
    ///
    public init(from decoder: Decoder) throws {
        guard let orderID = decoder.userInfo[.orderID] as? Int else {
            throw RefundDecodingError.missingOrderID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let refundID = try container.decode(Int.self, forKey: .refundID)
        let dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated) ?? Date()
        let amount = try container.decode(String.self, forKey: .amount)
        let reason = try container.decode(String.self, forKey: .reason)
        let refundedByUserID = try container.decode(Int.self, forKey: .refundedByUserID)
        let isAutomatedRefund = try container.decode(Bool.self, forKey: .automatedRefund)
        let items = try container.decode([OrderItemRefund].self, forKey: .items)

        self.init(refundID: refundID,
                  orderID: orderID,
                  dateCreated: dateCreated,
                  amount: amount,
                  reason: reason,
                  refundedByUserID: refundedByUserID,
                  isAutomatedRefund: isAutomatedRefund,
                  items: items)
    }

    // The public initializer for an encodable Refund
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(amount, forKey: .amount)
        try container.encode(reason, forKey: .reason)

        // take an orderItem and convert it to an orderItemRefund.

        // then encode it.
        try container.encode(orderItems, forKey: .orderItems)
    }
}


/// Defines all of the Refund CodingKeys
///
private extension Refund {

    enum CodingKeys: String, CodingKey {
        case refundID               = "id"
        case dateCreated            = "date_created_gmt"
        case amount
        case reason
        case refundedByUserID       = "refunded_by"
        case automatedRefund        = "refunded_payment"    // read-only
        case createAutomatedRefund  = "api_refund"          // write-only
        case orderItems             = "line_items"
    }
}


// MARK: - Comparable Conformance
//
extension Refund: Comparable {
    public static func == (lhs: Refund, rhs: Refund) -> Bool {
        return lhs.refundID == rhs.refundID &&
            lhs.orderID == rhs.orderID &&
            lhs.dateCreated == rhs.dateCreated &&
            lhs.amount == rhs.amount &&
            lhs.reason == rhs.reason &&
            lhs.refundedByUserID == rhs.refundedByUserID &&
            lhs.isAutomatedRefund == rhs.isAutomatedRefund &&
            (!lhs.orderItems.isEmpty && !rhs.orderItems.isEmpty) ?
        lhs.orderItems.count == rhs.orderItems.count &&
        lhs.orderItems.sorted() == rhs.orderItems.sorted() : true
    }

    public static func < (lhs: Refund, rhs: Refund) -> Bool {
        return lhs.orderID == rhs.orderID ||
            (lhs.orderID == rhs.orderID && lhs.refundID < rhs.refundID) ||
            (lhs.orderID == rhs.orderID && lhs.refundID == rhs.refundID &&
                lhs.dateCreated < rhs.dateCreated) ||
            (lhs.orderID == rhs.orderID && lhs.refundID == rhs.refundID &&
                lhs.dateCreated == rhs.dateCreated  &&
                lhs.amount < rhs.amount) ||
            (lhs.orderID == rhs.orderID && lhs.refundID == rhs.refundID &&
                lhs.dateCreated == rhs.dateCreated  &&
                lhs.amount == rhs.amount &&
                rhs.orderItems.count < rhs.orderItems.count) ||
            (lhs.orderID == rhs.orderID && lhs.refundID == rhs.refundID &&
                lhs.dateCreated == rhs.dateCreated &&
                lhs.amount == rhs.amount &&
                rhs.orderItems.count == rhs.orderItems.count)
    }
}


// MARK: - Decoding Errors
//
enum RefundDecodingError: Error {
    case missingOrderID
}
