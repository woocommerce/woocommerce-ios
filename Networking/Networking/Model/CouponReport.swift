import Codegen
import Foundation

public struct CouponReport {
    /// ID of the site that the coupon belongs to.
    /// Using a default here gives us the benefit of synthesized codable conformance.
    /// `private(set) public var` is required so that `siteID` will still be on the synthesized`init` which `copy()` uses.
    private(set) public var siteID: Int64 = 0

    /// ID of the coupon
    public let couponID: Int64

    /// Total amount deducted from orders using the coupon
    public let amount: Double

    /// Total number of orders that used the coupon
    public let ordersCount: Int64

    public init(siteID: Int64 = 0,
                couponID: Int64,
                amount: Double,
                ordersCount: Int64) {
        self.siteID = siteID
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
