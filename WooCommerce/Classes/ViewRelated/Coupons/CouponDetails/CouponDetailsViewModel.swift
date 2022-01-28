import Foundation
import Yosemite

/// View model for `CouponDetails` view
///
final class CouponDetailsViewModel: ObservableObject {
    /// ID of the coupon
    ///
    private let couponID: Int64

    /// ID of the site that the coupon belongs to
    ///
    private let siteID: Int64

    private let stores: StoresManager

    init(couponID: Int64,
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores) {
        self.couponID = couponID
        self.siteID = siteID
        self.stores = stores
    }
}
