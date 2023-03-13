import Foundation
import Yosemite

/// Helper to update an `order` given an `OrderCouponLine` input type.
///
struct CouponInputTransformer {

    /// Adds, deletes, or updates a coupon line input into an existing order.
    ///
    static func update(input: OrderCouponLine?, on order: Order) -> Order {
        // If input is `nil`, then we remove the first existing coupon line.
        guard let input = input else {
            let updatedLines = order.coupons.enumerated().map { index, line -> OrderCouponLine? in
                if index == 0 {
                    return nil
                }
                return OrderFactory.newOrderCouponLine(code: line.code)
            }.compactMap({ $0 })
            return order.copy(coupons: updatedLines)
        }

        // If there is no existing coupon lines, we insert the input one.
        guard order.coupons.isNotEmpty else {
            return order.copy(coupons: [input])
        }

        // If there are existing coupon lines replace the first coupon line
        var updatedCodes = order.coupons.map({ $0.code })
        updatedCodes[0] = input.code
        return order.copy(coupons: updatedCodes.map({ OrderFactory.newOrderCouponLine(code: $0) }))
    }
}
