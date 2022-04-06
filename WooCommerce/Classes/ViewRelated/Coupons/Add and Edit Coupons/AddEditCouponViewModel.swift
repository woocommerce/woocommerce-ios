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

    /// Text representing the label of the amount field, localized based on discount type.
    ///
    var amountLabel: String {
        switch discountType {
        case .percent:
            return Localization.amountPercent
        default:
            let currencyCode = ServiceLocator.currencySettings.currencyCode
            let unit = ServiceLocator.currencySettings.symbol(from: currencyCode)
            return String.localizedStringWithFormat(Localization.amountFixedDiscount, unit)
        }
    }

    /// Text representing the label of the amount textfield subtitle, localized based on discount type.
    ///
    var amountSubtitleLabel: String {
        switch discountType {
        case .percent:
            return Localization.amountPercentSubtitle
        default:
            return Localization.amountFixedDiscountSubtitle
        }
    }

    private var coupon: Coupon?

    // Fields
    @Published var amountField = String()
    @Published var codeField = String()

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

        // Populate fields
        amountField = existingCoupon.amount
        codeField = existingCoupon.code
    }

    private enum EditingOption {
        case creation
        case editing
    }
}

// MARK: - Constants
//
private extension AddEditCouponViewModel {

    enum Localization {
        static let amountPercent = NSLocalizedString("Amount (%)",
                                                     comment: "Title of the Amount field in the Coupon Edit" +
                                                     " or Creation screen for a percentage discount coupon.")
        static let amountFixedDiscount = NSLocalizedString("Amount (%@)",
                                                           comment: "Title of the Amount field on the Coupon Edit" +
                                                           " or Creation screen for a fixed amount discount coupon." +
                                                           "Reads like: Amount ($)")
        static let amountPercentSubtitle = NSLocalizedString("Set the percentage of the discount you want to offer.",
                                                             comment: "Subtitle of the Amount field in the Coupon Edit" +
                                                             " or Creation screen for a percentage discount coupon.")
        static let amountFixedDiscountSubtitle = NSLocalizedString("Set the fixed amount of the discount you want to offer.",
                                                                   comment: "Subtitle of the Amount field on the Coupon Edit" +
                                                                   " or Creation screen for a fixed amount discount coupon.")
    }
}
