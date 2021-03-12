import Foundation


/// Represents a CouponLine Entity within an Order.
///
public struct OrderCouponLine: Decodable, GeneratedFakeable {
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
    public static func == (lhs: OrderCouponLine, rhs: OrderCouponLine) -> Bool {
        return lhs.couponID == rhs.couponID &&
            lhs.code == rhs.code &&
            lhs.discount == rhs.discount &&
            lhs.discountTax == rhs.discountTax
    }

    public static func < (lhs: OrderCouponLine, rhs: OrderCouponLine) -> Bool {
        return lhs.couponID < rhs.couponID ||
            (lhs.couponID == rhs.couponID && lhs.code < rhs.code) ||
            (lhs.couponID == rhs.couponID && lhs.code == rhs.code && lhs.discount < rhs.discount)
    }
}
