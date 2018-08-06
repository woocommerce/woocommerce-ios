import Foundation
import Storage


// MARK: - Storage.OrderCoupon: ReadOnlyConvertible
//
extension Storage.OrderCoupon: ReadOnlyConvertible {

    /// Indicates if the receiver is the Storage.Entity, backing up the specified ReadOnly.Entity.
    ///
    public func represents(readOnlyEntity: Any) -> Bool {
        guard let readOnlyCoupon = readOnlyEntity as? Yosemite.OrderCouponLine else {
            return false
        }

// TODO: Add order.orderID + order.siteID Check
        return readOnlyCoupon.couponID == Int(couponID)
    }

    /// Updates the Storage.OrderCoupon with the ReadOnly.
    ///
    public func update(with orderCoupon: Yosemite.OrderCouponLine) {
        couponID = Int64(orderCoupon.couponID)
        code = orderCoupon.code
        discount = orderCoupon.discount
        discountTax = orderCoupon.discountTax
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderCouponLine {
        return OrderCouponLine(couponID: Int(couponID),
                               code: code ?? "",
                               discount: discount ?? "",
                               discountTax: discountTax ?? "")
    }
}
