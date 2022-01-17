import Codegen
import Foundation

public struct CouponReport {
    /// ID of the coupon
    public let couponID: Int64

    /// Total amount deducted from orders using the coupon
    public let amount: Double

    /// Total number of orders that used the coupon
    public let ordersCount: Int64

    public init(couponID: Int64,
                amount: Double,
                ordersCount: Int64) {
        self.couponID = couponID
        self.amount = amount
        self.ordersCount = ordersCount
    }
}

// MARK: - Decodable Conformance
//
extension CouponReport: Decodable {
    /// Defines all of the CouponReport CodingKeys
    /// The model is intended to be decoded with`JSONDecoder.KeyDecodingStrategy.convertFromSnakeCase`
    /// so any specific `CodingKeys` provided here should be in camel case.
    enum CodingKeys: String, CodingKey {
        case couponID, amount, ordersCount
    }
}

// MARK: - Other Conformance
//
extension CouponReport: GeneratedCopiable, GeneratedFakeable, Equatable {}

extension CouponReport {
    /// JSON decoder appropriate for `CouponReport` responses.
    ///
    static let decoder: JSONDecoder = {
        let couponDecoder = JSONDecoder()
        couponDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return couponDecoder
    }()
}
