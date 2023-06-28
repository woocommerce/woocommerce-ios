import Foundation
import Yosemite

/// Helper to update an `order` given an `OrderCouponLine` input type.
///
struct CouponInputTransformer {

    /// Adds a coupon line input into an existing order.
    /// If the order already has that coupon line it does nothing
    ///
    static func append(input: String, on order: Order) -> Order {
        var updatedCodes = order.coupons.map({ $0.code })

        guard !updatedCodes.contains(input) else {
            return order
        }

        updatedCodes.append(input)
        return order.copy(coupons: updatedCodes.map({ OrderFactory.newOrderCouponLine(code: $0) }))
    }

    /// Removes a coupon line input into an existing order.
    /// If the order does not have that coupon added it does nothing
    ///
    static func remove(code: String, on order: Order) -> Order {
        var updatedCodes = order.coupons.map({ $0.code })

        guard updatedCodes.contains(code) else {
            return order
        }

        updatedCodes.removeAll(where: { $0 == code })
        return order.copy(coupons: updatedCodes.map({ OrderFactory.newOrderCouponLine(code: $0) }))
    }

    /// Removes the last added coupon line from the order.
    /// If the order does not have that coupon added it does nothing
    ///
    static func removeLastCoupon(on order: Order) -> Order {
        var updatedCodes = order.coupons.map({ $0.code })

        guard updatedCodes.isNotEmpty else {
            return order
        }

        updatedCodes.removeLast()
        return order.copy(coupons: updatedCodes.map({ OrderFactory.newOrderCouponLine(code: $0) }))
    }
}
