import Foundation
import Codegen

/// Represents a CouponLine Entity within an Order.
///
public struct OrderCouponLine: Codable, Equatable, Sendable, GeneratedFakeable, GeneratedCopiable {
    public let couponID: Int64
    public let code: String
    public let discount: String
    public let discountTax: String

    /// OrderCouponLine struct initializer.
    ///
    public init(couponID: Int64, code: String, discount: String, discountTax: String) {
        self.couponID = couponID
        self.code = code
        self.discount = discount
        self.discountTax = discountTax
    }
}

// MARK: Codable
extension OrderCouponLine {

    /// Encodes OrderCouponLine writable fields.
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(code, forKey: .code)
    }
}

/// Defines all of the CouponLine's CodingKeys.
///
private extension OrderCouponLine {

    enum CodingKeys: String, CodingKey {
        case couponID       = "id"
        case code           = "code"
        case discount       = "discount"
        case discountTax    = "discount_tax"
    }
}


// MARK: - Comparable Conformance
//
extension OrderCouponLine: Comparable {
    public static func < (lhs: OrderCouponLine, rhs: OrderCouponLine) -> Bool {
        return lhs.couponID < rhs.couponID ||
            (lhs.couponID == rhs.couponID && lhs.code < rhs.code) ||
            (lhs.couponID == rhs.couponID && lhs.code == rhs.code && lhs.discount < rhs.discount)
    }
}
