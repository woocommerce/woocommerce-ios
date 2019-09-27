import Foundation


/// Order Details contain a condensed report on refunds.
/// This model represents the refunds found there.
/// See also `Refund` for a detailed refund model.
///
public struct OrderRefundCondensed: Decodable {
    public let siteID: Int
    public let refundID: Int
    public let reason: String?
    public let total: String


    /// OrderRefund struct initializer.
    ///
    public init(siteID: Int,
                refundID: Int,
                reason: String?,
                total: String) {
        self.siteID = siteID
        self.refundID = refundID
        self.reason = reason
        self.total = total
    }


    /// The public initializer for OrderRefund.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int else {
            throw OrderRefundDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let refundID = try container.decode(Int.self, forKey: .refundID)
        let reason = try container.decodeIfPresent(String.self, forKey: .reason)
        let total = try container.decode(String.self, forKey: .total)

        self.init(siteID: siteID,
                  refundID: refundID,
                  reason: reason,
                  total: total)
    }
}


/// Defines all of the OrderRefund CodingKeys
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
        return lhs.siteID == rhs.siteID &&
            lhs.refundID == rhs.refundID &&
            lhs.reason == rhs.reason &&
            lhs.total == rhs.total
    }

    public static func < (lhs: OrderRefundCondensed, rhs: OrderRefundCondensed) -> Bool {
        return lhs.refundID == rhs.refundID && lhs.total < rhs.total
    }
}

// MARK: - Decoding Errors
//
enum OrderRefundDecodingError: Error {
    case missingSiteID
}
