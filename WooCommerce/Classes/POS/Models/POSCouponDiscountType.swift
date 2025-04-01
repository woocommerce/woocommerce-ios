import Foundation
import struct Yosemite.Coupon

struct POSCouponDiscountType: Identifiable, Equatable {
    var id: String { discountType.rawValue }
    let discountType: Coupon.DiscountType
}
