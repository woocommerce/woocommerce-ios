import Foundation
import Yosemite

/// View model for `AddEditCoupon` view
///
final class AddEditCouponViewModel: ObservableObject {

    private let siteID: Int64
    let editingOption: EditingOption
    let discountType: Coupon.DiscountType
    var titleView: String {
        switch editingOption {
        case .creation:
            switch discountType {
            case .percent:
                return Localization.titleCreatePercentageDiscount
            case .fixedCart:
                return Localization.titleCreateFixedCardDiscount
            case .fixedProduct:
                return Localization.titleCreateFixedProductDiscount
            default:
                return String()
            }
        case .editing:
            switch discountType {
            case .percent:
                return Localization.titleEditPercentageDiscount
            case .fixedCart:
                return Localization.titleEditFixedCardDiscount
            case .fixedProduct:
                return Localization.titleEditFixedProductDiscount
            default:
                return String()
            }
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

    enum EditingOption {
        case creation
        case editing
    }
}

// MARK: - Constants
//
private extension AddEditCouponViewModel {
    enum Localization {
        static let titleEditPercentageDiscount = NSLocalizedString(
            "Edit percentage discount",
            comment: "Title of the view for editing a coupon with percentage discount.")
        static let titleEditFixedCardDiscount = NSLocalizedString(
            "Edit fixed card discount",
            comment: "Title of the view for editing a coupon with fixed card discount.")
        static let titleEditFixedProductDiscount = NSLocalizedString(
            "Edit fixed product discount",
            comment: "Title of the view for editing a coupon with fixed product discount.")
        static let titleCreatePercentageDiscount = NSLocalizedString(
            "Create percentage discount",
            comment: "Title of the view for creating a coupon with percentage discount.")
        static let titleCreateFixedCardDiscount = NSLocalizedString(
            "Create fixed card discount",
            comment: "Title of the view for creating a coupon with fixed card discount.")
        static let titleCreateFixedProductDiscount = NSLocalizedString(
            "Create fixed product discount",
            comment: "Title of the view for creating a coupon with fixed product discount.")
    }
}
