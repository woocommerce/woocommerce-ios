import Foundation
import Yosemite
import UIKit
import protocol Storage.StorageManagerType

/// View model for `AddEditCoupon` view
///
final class AddEditCouponViewModel: ObservableObject {

    private let siteID: Int64

    /// Based on the Editing Option, the `AddEditCoupon` view can be in Creation or Editing mode.
    ///
    private let editingOption: EditingOption

    private let discountType: Coupon.DiscountType

    private let onCompletion: ((Result<Coupon, Error>) -> Void)

    /// Defines the current notice that should be shown.
    /// Defaults to `nil`.
    ///
    @Published var notice: Notice?

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
            return .content(expiryDateField?.toString(dateStyle: .long, timeStyle: .none, timeZone: timezone) ?? "")
        }

        return .placeholder(Localization.couponExpiryDatePlaceholder)
    }

    /// View model for the product selector
    ///
    var productSelectorViewModel: ProductSelectorViewModel {
        ProductSelectorViewModel(siteID: siteID, selectedItemIDs: productOrVariationIDs, onMultipleSelectionCompleted: { [weak self] ids in
            self?.productOrVariationIDs = ids
        })
    }

    /// Title for the Edit Products button with the number of selected products.
    ///
    var editProductsButtonTitle: String {
        String.localizedStringWithFormat(Localization.editProductsButton, productOrVariationIDs.count)
    }

    /// View model for the category selector
    ///
    var categorySelectorViewModel: ProductCategorySelectorViewModel {
        .init(siteID: siteID, selectedCategories: categoryIDs) { [weak self] categories in
            self?.categoryIDs = categories.map { $0.categoryID }
        }
    }

    /// Title for the Edit Categories button with the number of selected product categories.
    ///
    var editCategoriesButtonTitle: String {
        String.localizedStringWithFormat(Localization.editProductCategoriesButton, categoryIDs.count)
    }

    /// Whether the coupon is applicable to any specified products.
    ///
    var hasSelectedProducts: Bool {
        productOrVariationIDs.isNotEmpty
    }

    /// Whether the coupon is applicable to any specified product categories.
    ///
    var hasSelectedCategories: Bool {
        categoryIDs.isNotEmpty
    }

    private(set) var coupon: Coupon?
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    let timezone: TimeZone

    /// When the view is updating or creating a new Coupon remotely.
    ///
    @Published var isLoading: Bool = false

    // Fields
    @Published var amountField: String
    @Published var codeField: String
    @Published var descriptionField: String
    @Published var expiryDateField: Date?
    @Published var freeShipping: Bool
    @Published var couponRestrictionsViewModel: CouponRestrictionsViewModel
    @Published var productOrVariationIDs: [Int64]
    @Published var categoryIDs: [Int64]

    /// Init method for coupon creation
    ///
    init(siteID: Int64,
         discountType: Coupon.DiscountType,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         timezone: TimeZone = .siteTimezone,
         onCompletion: @escaping ((Result<Coupon, Error>) -> Void)) {
        self.siteID = siteID
        editingOption = .creation
        self.discountType = discountType
        self.stores = stores
        self.storageManager = storageManager
        self.timezone = timezone
        self.onCompletion = onCompletion

        amountField = String()
        codeField = String()
        descriptionField = String()
        expiryDateField = nil
        freeShipping = false
        couponRestrictionsViewModel = CouponRestrictionsViewModel(siteID: siteID)
        productOrVariationIDs = []
        categoryIDs = []
    }

    /// Init method for coupon editing
    ///
    init(existingCoupon: Coupon,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         timezone: TimeZone = .siteTimezone,
         onCompletion: @escaping ((Result<Coupon, Error>) -> Void)) {
        siteID = existingCoupon.siteID
        coupon = existingCoupon
        editingOption = .editing
        discountType = existingCoupon.discountType
        self.stores = stores
        self.storageManager = storageManager
        self.timezone = timezone
        self.onCompletion = onCompletion

        // Populate fields
        amountField = existingCoupon.amount
        codeField = existingCoupon.code
        descriptionField = existingCoupon.description
        expiryDateField = existingCoupon.dateExpires
        freeShipping = existingCoupon.freeShipping
        couponRestrictionsViewModel = CouponRestrictionsViewModel(coupon: existingCoupon)
        productOrVariationIDs = existingCoupon.productIds
        categoryIDs = existingCoupon.productCategories
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

    func updateCoupon(coupon: Coupon) {
        if let validationError = validateCouponLocally(coupon) {
            notice = NoticeFactory.createCouponErrorNotice(validationError,
                                                           editingOption: editingOption)
            onCompletion(.failure(validationError))
            return
        }

        isLoading = true
        let action = CouponAction.updateCoupon(coupon, siteTimezone: timezone) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(_):
                break
            case .failure(let error):
                DDLogError("⛔️ Error updating the coupon: \(error)")
                self.notice = NoticeFactory.createCouponErrorNotice(.other(error: error),
                                                                    editingOption: self.editingOption)
            }
            self.isLoading = false
            self.onCompletion(result)
        }
        stores.dispatch(action)
    }

    var populatedCoupon: Coupon {
        // TODO: Fill all the missing data (like `productIds`, `excludedProductIds`, `productCategories`, `excludedProductCategories`)
        coupon?.copy(code: codeField,
                     amount: amountField,
                     discountType: discountType,
                     description: descriptionField,
                     dateExpires: expiryDateField?.startOfDay(timezone: timezone),
                     individualUse: couponRestrictionsViewModel.individualUseOnly,
                     productIds: productOrVariationIDs,
                     excludedProductIds: couponRestrictionsViewModel.excludedProductOrVariationIDs,
                     usageLimit: Int64(couponRestrictionsViewModel.usageLimitPerCoupon),
                     usageLimitPerUser: Int64(couponRestrictionsViewModel.usageLimitPerUser),
                     limitUsageToXItems: Int64(couponRestrictionsViewModel.limitUsageToXItems),
                     freeShipping: freeShipping,
                     productCategories: categoryIDs,
                     excludedProductCategories: couponRestrictionsViewModel.excludedCategoryIDs,
                     excludeSaleItems: couponRestrictionsViewModel.excludeSaleItems,
                     minimumAmount: couponRestrictionsViewModel.minimumSpend,
                     maximumAmount: couponRestrictionsViewModel.maximumSpend,
                     emailRestrictions: couponRestrictionsViewModel.allowedEmails.components(separatedBy: ", ")) ??
        Coupon(siteID: siteID,
               couponID: -1,
               code: codeField,
               amount: amountField,
               dateCreated: Date(),
               dateModified: Date(),
               discountType: discountType,
               description: descriptionField,
               dateExpires: expiryDateField?.startOfDay(timezone: timezone),
               usageCount: 0,
               individualUse: couponRestrictionsViewModel.individualUseOnly,
               productIds: [],
               excludedProductIds: [],
               usageLimit: Int64(couponRestrictionsViewModel.usageLimitPerCoupon),
               usageLimitPerUser: Int64(couponRestrictionsViewModel.usageLimitPerUser),
               limitUsageToXItems: Int64(couponRestrictionsViewModel.limitUsageToXItems),
               freeShipping: freeShipping,
               productCategories: [],
               excludedProductCategories: [],
               excludeSaleItems: couponRestrictionsViewModel.excludeSaleItems,
               minimumAmount: couponRestrictionsViewModel.minimumSpend,
               maximumAmount: couponRestrictionsViewModel.maximumSpend,
               emailRestrictions: couponRestrictionsViewModel.allowedEmails.components(separatedBy: ", "),
               usedBy: [])
    }

    func validateCouponLocally(_ coupon: Coupon) -> CouponError? {
        if coupon.code.isEmpty {
            return .couponCodeEmpty
        }

        return nil
    }

    enum EditingOption {
        case creation
        case editing
    }

    enum CouponError: Error, Equatable {
        case couponCodeEmpty
        case other(error: Error)

        static func ==(lhs: CouponError, rhs: CouponError) -> Bool {
            return lhs.localizedDescription == rhs.localizedDescription
        }
    }
}

// MARK: - Constants
//
private extension AddEditCouponViewModel {

    /// Coupon notices
    ///
    enum NoticeFactory {
        /// Returns a default coupon editing/creation error notice.
        ///
        static func createCouponErrorNotice(_ couponError: AddEditCouponViewModel.CouponError,
                                            editingOption: AddEditCouponViewModel.EditingOption) -> Notice {
            switch couponError {
            case .couponCodeEmpty:
                return Notice(title: Localization.errorCouponCodeEmpty, feedbackType: .error)
            default:
                switch editingOption {
                case .editing:
                    return Notice(title: Localization.genericUpdateCouponError, feedbackType: .error)
                case .creation:
                    return Notice(title: Localization.genericCreateCouponError, feedbackType: .error)
                }
            }
        }
    }

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
        static let errorCouponCodeEmpty = NSLocalizedString("The coupon code couldn't be empty",
                                                            comment: "Error message in the Add Edit Coupon screen when the coupon code is empty.")
        static let genericUpdateCouponError = NSLocalizedString("Something went wrong while updating the coupon.",
                                                                comment: "Error message in the Add Edit Coupon screen " +
                                                                "when the update of the coupon goes in error.")
        static let genericCreateCouponError = NSLocalizedString("Something went wrong while creating the coupon.",
                                                                comment: "Error message in the Add Edit Coupon screen " +
                                                                "when the creation of the coupon goes in error.")
        static let editProductsButton = NSLocalizedString(
            "Edit Products (%1$d)",
            comment: "Button specifying the number of products applicable to a coupon in the view for adding or editing a coupon. " +
            "Reads like: Edit Products (2)")
        static let editProductCategoriesButton = NSLocalizedString(
            "Edit Product Categories (%1$d)",
            comment: "Button for specify the product categories where a coupon can be applied in the view for adding or editing a coupon. " +
            "Reads like: Edit Categories")
    }
}
