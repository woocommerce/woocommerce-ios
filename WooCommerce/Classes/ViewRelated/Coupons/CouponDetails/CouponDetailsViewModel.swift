import Foundation
import Yosemite

/// View model for `CouponDetails` view
///
final class CouponDetailsViewModel: ObservableObject {
    /// The current coupon
    ///
    private let coupon: Coupon

    private let stores: StoresManager

    init(coupon: Coupon,
         stores: StoresManager = ServiceLocator.stores) {
        self.coupon = coupon
        self.stores = stores
    }
}
