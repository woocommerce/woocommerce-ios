import Foundation


/// Represents a Refund entity.
///
public struct Refund: Decodable {
    public let refundID: Int
    public let orderID: Int
    public let dateCreated: Date //gmt
    public let amount: String
    public let reason: String
    public let refundedByUserID: Int
    public let automatedRefund: Bool
    public let orderItems: [OrderItem]

    /// Refund struct initializer
    ///
    public init(refundID: Int,
                orderID: Int,
                dateCreated: Date,
                amount: String,
                reason: String,
                refundedByUserID: Int,
                automatedRefund: Bool,
                orderItems: [OrderItem]) {
        self.refundID = refundID
        self.orderID = orderID
        self.dateCreated = dateCreated
        self.amount = amount
        self.reason = reason
        self.refundedByUserID = refundedByUserID
        self.automatedRefund = automatedRefund
        self.orderItems = orderItems
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
        let automatedRefund = try container.decode(Bool.self, forKey: .automatedRefund)
        let orderItems = try container.decode([OrderItem].self, forKey: .orderItems)

        self.init(refundID: refundID,
                  orderID: orderID,
                  dateCreated: dateCreated,
                  amount: amount,
                  reason: reason,
                  refundedByUserID: refundedByUserID,
                  automatedRefund: automatedRefund,
                  orderItems: orderItems)
    }
}


/// Defines all of the Refund CodingKeys
///
private extension Refund {

    enum CodingKeys: String, CodingKey {
        case refundID           = "id"
        case dateCreated        = "date_created_gmt"
        case amount
        case reason
        case refundedByUserID   = "refunded_by"
        case automatedRefund    = "refunded_Payment"
        case orderItems         = "line_items"
    }
}


// MARK: - Decoding Errors
//
enum RefundDecodingError: Error {
    case missingOrderID
}
