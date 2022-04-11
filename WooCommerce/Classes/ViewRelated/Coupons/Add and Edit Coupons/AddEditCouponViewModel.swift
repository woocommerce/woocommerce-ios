import Foundation
import Yosemite
import UIKit

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

    /// Label representing the label of the amount field, localized based on discount type.
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

    /// Label representing the label of the amount textfield subtitle, localized based on discount type.
    ///
    var amountSubtitleLabel: String {
        switch discountType {
        case .percent:
            return Localization.amountPercentSubtitle
        default:
            return Localization.amountFixedDiscountSubtitle
        }
    }

    /// Icon of the button for editing a coupon description, based on the field (populated or not).
    ///
    var editDescriptionIcon: UIImage {
        if descriptionField.isEmpty {
            return .plusImage
        }
        return .pencilImage
    }

    /// Label of the button for editing a coupon description, based on the field (populated or not).
    ///
    var editDescriptionLabel: String {
        if descriptionField.isEmpty {
            return Localization.addDescriptionButton
        }
        return Localization.editDescriptionButton
    }

    /// The value for populating the coupon expiry date field based on the `expiryDateField`.
    ///
    var expiryDateValue: TitleAndValueRow.Value {
        guard expiryDateField == nil else {
            return .content(expiryDateField?.toString(dateStyle: .long, timeStyle: .none) ?? "")
        }

        return .placeholder(Localization.couponExpiryDatePlaceholder)
    }

    private(set) var coupon: Coupon?

    // Fields
    @Published var amountField: String
    @Published var codeField: String
    @Published var descriptionField: String
    @Published var expiryDateField: Date?
    @Published var freeShipping: Bool

    /// Init method for coupon creation
    ///
    init(siteID: Int64,
         discountType: Coupon.DiscountType) {
        self.siteID = siteID
        editingOption = .creation
        self.discountType = discountType

        amountField = String()
        codeField = String()
        descriptionField = String()
        expiryDateField = nil
        freeShipping = false
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
        descriptionField = existingCoupon.description
        expiryDateField = existingCoupon.dateExpires
        freeShipping = existingCoupon.freeShipping
    }

    /// The method will generate a code in the same way as the existing admin website code does.
    /// https://github.com/woocommerce/woocommerce/blob/23710744c01ded649d6a94a4eaea8745e543159f/assets/js/admin/meta-boxes-coupon.js#L53
    /// We will loop to select 8 characters from the set `ABCDEFGHJKMNPQRSTUVWXYZ23456789` at random using `arc4random_uniform` for randomness.
    /// https://github.com/woocommerce/woocommerce/blob/2e60d47a019a6e35f066f3ef43a56c0e761fc8e3/includes/admin/class-wc-admin-assets.php#L295
    ///
    func generateRandomCouponCode() {
        let dictionary: [String] = "ABCDEFGHJKMNPQRSTUVWXYZ23456789".map { String($0) }
        let generatedCodeLength = 8

        var code: String = ""
        for _ in 0 ..< generatedCodeLength {
            code += dictionary.randomElement() ?? ""
        }

        codeField = code
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
        static let addDescriptionButton = NSLocalizedString("Add Description (Optional)",
                                                            comment: "Button for adding a description to a coupon in the view for adding or editing a coupon.")
        static let editDescriptionButton = NSLocalizedString("Edit Description",
                                                             comment: "Button for editing the description of a coupon in the" +
                                                             " view for adding or editing a coupon.")
        static let couponExpiryDatePlaceholder = NSLocalizedString(
            "None",
            comment: "Coupon expiry date placeholder in the view for adding or editing a coupon")
    }
}
