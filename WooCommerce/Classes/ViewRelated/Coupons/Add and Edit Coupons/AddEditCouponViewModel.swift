import Foundation
import Yosemite

/// View model for `AddEditCoupon` view
///
final class AddEditCouponViewModel: ObservableObject {

    private let siteID: Int64

    /// Based on the Editing Option, the `AddEditCoupon` view can be in Creation or Editing mode.
    ///
    private let editingOption: EditingOption

    private let discountType: Coupon.DiscountType

    var title: String {
        switch editingOption {
        case .creation:
            return discountType.titleCreateCoupon
        case .editing:
            return discountType.titleEditCoupon
        }
    }

    @Published private(set) var coupon: Coupon?

    /// Init method for coupon creation
    ///
    init(siteID: Int64,
         discountType: Coupon.DiscountType) {
        self.siteID = siteID
        editingOption = .creation
        self.discountType = discountType
    }

    /// Init method for coupon editing
    ///
    init(existingCoupon: Coupon) {
        siteID = existingCoupon.siteID
        coupon = existingCoupon
        editingOption = .editing
        discountType = existingCoupon.discountType
    }

    private enum EditingOption {
        case creation
        case editing
    }
}
