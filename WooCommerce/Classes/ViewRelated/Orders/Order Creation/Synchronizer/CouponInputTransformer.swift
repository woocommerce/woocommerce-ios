import Foundation
import Yosemite

/// Helper to update an `order` given an `OrderCouponLine` input type.
///
struct CouponInputTransformer {

    /// Adds a coupon line input into an existing order.
    /// If the order already has that coupon line it does nothing
    ///
    static func append(input: String, on order: Order) -> Order {
        let existingCouponCodes = order.coupons.map({ $0.code })
        guard !existingCouponCodes.contains(input) else {
            return order
        }

        return order.copy(coupons: order.coupons + [OrderFactory.newOrderCouponLine(code: input)])
    }

    /// Removes a coupon line input from an existing order.
    /// If the order does not have that coupon added it does nothing
    ///
    static func remove(code: String, from order: Order) -> Order {
        var updatedCoupons = order.coupons
        updatedCoupons.removeAll(where: { $0.code == code })

        return order.copy(coupons: updatedCoupons)
    }
}
