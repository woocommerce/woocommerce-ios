import Foundation
import Yosemite

/// View model for `AddEditCoupon` view
///
final class AddEditCouponViewModel: ObservableObject {

    let editingOption: EditingOption
    let siteID: Int64
    @Published private(set) var coupon: Coupon?

    /// Init method for coupon creation
    ///
    init(siteID: Int64,
         discountType: Coupon.DiscountType) {
        self.siteID = siteID
        editingOption = .creation
    }

    /// Init method for coupon editing
    ///
    init(existingCoupon: Coupon) {
        siteID = existingCoupon.siteID
        coupon = existingCoupon
        editingOption = .editing
    }


    enum EditingOption {
        case creation
        case editing
    }
}
