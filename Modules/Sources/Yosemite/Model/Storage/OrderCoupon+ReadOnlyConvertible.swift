import Foundation
import Storage


// MARK: - Storage.OrderCoupon: ReadOnlyConvertible
//
extension Storage.OrderCoupon: ReadOnlyConvertible {

    /// Updates the Storage.OrderCoupon with the ReadOnly.
    ///
    public func update(with orderCoupon: Yosemite.OrderCouponLine) {
        couponID = orderCoupon.couponID
        code = orderCoupon.code
        discount = orderCoupon.discount
        discountTax = orderCoupon.discountTax
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderCouponLine {
        return OrderCouponLine(couponID: couponID,
                               code: code ?? "",
                               discount: discount ?? "",
                               discountTax: discountTax ?? "")
    }
}
