import Foundation
import Yosemite
import UIKit
import WooFoundation
import protocol Storage.StorageManagerType

/// View model for `AddEditCoupon` view
///
final class AddEditCouponViewModel: ObservableObject {

    private let siteID: Int64

    /// Based on the Editing Option, the `AddEditCoupon` view can be in Creation or Editing mode.
    ///
    private let editingOption: EditingOption

    private let onSuccess: (Coupon) -> Void

    /// Defines the current notice that should be shown.
    /// Defaults to `nil`.
    ///
    @Published var notice: Notice?

    var title: String {
        switch editingOption {
        case .creation:
            return Localization.createCouponTitle
        case .editing:
            return Localization.editCouponTitle
        }
    }

    /// Defines the main action button text that should be shown.
    /// Switching between `Create` or `Save` action.
    ///
    var addEditCouponButtonText: String {
        switch editingOption {
        case .creation:
            return Localization.createButton
        case .editing:
            return Localization.saveButton
        }
    }

    /// The value for populating the coupon discount type field based on the `discountType`.
    ///
    var discountTypeValue: TitleAndValueRow.Value {
        return .content(discountType.localizedName)
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

    var shareCouponMessage: String {
        coupon?.generateShareMessage(currencySettings: currencySettings) ?? ""
    }

    var hasChangesMade: Bool {
        guard editingOption == .editing else { return true }
        let coupon = populatedCoupon
        return checkDiscountTypeUpdated(for: coupon) ||
        checkAmountUpdated(for: coupon) ||
        checkDescriptionUpdated(for: coupon) ||
        checkCouponCodeUpdated(for: coupon) ||
        checkAllowedProductsAndCategoriesUpdated(for: coupon) ||
        checkExpiryDateUpdated(for: coupon) ||
        checkFreeShippingUpdated(for: coupon) ||
        checkUsageRestrictionsUpdated(for: coupon)
    }

    private(set) var coupon: Coupon?
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let currencySettings: CurrencySettings
    let timezone: TimeZone

    /// When the view is updating or creating a new Coupon remotely.
    ///
    @Published var isLoading: Bool = false

    // Fields
    @Published var discountType: Coupon.DiscountType {
        didSet {
            couponRestrictionsViewModel.onDiscountTypeChanged(discountType: discountType)
        }
    }
    @Published var amountField: String
    @Published var codeField: String
    @Published var descriptionField: String
    @Published var expiryDateField: Date?
    @Published var freeShipping: Bool
    @Published var couponRestrictionsViewModel: CouponRestrictionsViewModel
    @Published var productOrVariationIDs: [Int64]
    @Published var categoryIDs: [Int64]
    @Published var showingCouponCreationSuccess: Bool = false

    /// Init method for coupon creation
    ///
    init(siteID: Int64,
         discountType: Coupon.DiscountType,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         timezone: TimeZone = .siteTimezone,
         onSuccess: @escaping (Coupon) -> Void) {
        self.siteID = siteID
        editingOption = .creation
        self.discountType = discountType
        self.stores = stores
        self.storageManager = storageManager
        self.currencySettings = currencySettings
        self.timezone = timezone
        self.onSuccess = onSuccess

        amountField = String()
        codeField = String()
        descriptionField = String()
        expiryDateField = nil
        freeShipping = false
        couponRestrictionsViewModel = CouponRestrictionsViewModel(siteID: siteID)
        productOrVariationIDs = []
        categoryIDs = []
        generateRandomCouponCode()
    }

    /// Init method for coupon editing
    ///
    init(existingCoupon: Coupon,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         timezone: TimeZone = .siteTimezone,
         onSuccess: @escaping (Coupon) -> Void) {
        siteID = existingCoupon.siteID
        coupon = existingCoupon
        editingOption = .editing
        discountType = existingCoupon.discountType
        self.stores = stores
        self.storageManager = storageManager
        self.currencySettings = currencySettings
        self.timezone = timezone
        self.onSuccess = onSuccess

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

    func completeCouponAddEdit(coupon: Coupon, onUpdateFinished: @escaping () -> Void) {
        switch editingOption {
        case .creation:
            createCoupon(coupon: coupon)
        case .editing:
            updateCoupon(coupon: coupon, onUpdateFinished: onUpdateFinished)
        }
    }

    private func createCoupon(coupon: Coupon) {
        trackCouponCreateInitiated(with: coupon)

        if let validationError = validateCouponLocally(coupon) {
            notice = NoticeFactory.createCouponErrorNotice(validationError,
                    editingOption: editingOption)
            return
        }

        isLoading = true
        let action = CouponAction.createCoupon(coupon, siteTimezone: timezone) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let coupon):
                ServiceLocator.analytics.track(.couponCreationSuccess)
                self.coupon = coupon
                self.onSuccess(coupon)
                self.showingCouponCreationSuccess = true
            case .failure(let error):
                DDLogError("⛔️ Error creating the coupon: \(error)")
                ServiceLocator.analytics.track(.couponCreationFailed, withError: error)
                self.notice = NoticeFactory.createCouponErrorNotice(.other(error: error),
                        editingOption: self.editingOption)
            }
        }
        stores.dispatch(action)
    }

    private func updateCoupon(coupon: Coupon, onUpdateFinished: @escaping () -> Void) {
        trackCouponUpdateInitiated(with: coupon)

        if let validationError = validateCouponLocally(coupon) {
            notice = NoticeFactory.createCouponErrorNotice(validationError,
                                                           editingOption: editingOption)
            return
        }

        isLoading = true
        let action = CouponAction.updateCoupon(coupon, siteTimezone: timezone) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let updatedCoupon):
                ServiceLocator.analytics.track(.couponUpdateSuccess)
                self.onSuccess(updatedCoupon)
                onUpdateFinished()
            case .failure(let error):
                DDLogError("⛔️ Error updating the coupon: \(error)")
                ServiceLocator.analytics.track(.couponUpdateFailed, withError: error)
                self.notice = NoticeFactory.createCouponErrorNotice(.other(error: error),
                                                                    editingOption: self.editingOption)
            }
        }
        stores.dispatch(action)
    }

    var populatedCoupon: Coupon {
        let emailRestrictions: [String] = {
            if couponRestrictionsViewModel.allowedEmails.isEmpty {
                return []
            }
            return couponRestrictionsViewModel.allowedEmails.components(separatedBy: ", ")
        }()

        return Coupon(siteID: siteID,
                      couponID: coupon?.couponID ?? -1,
                      code: codeField,
                      amount: amountField,
                      dateCreated: coupon?.dateCreated ?? Date(),
                      dateModified: coupon?.dateModified ?? Date(),
                      discountType: discountType,
                      description: descriptionField,
                      dateExpires: expiryDateField?.startOfDay(timezone: timezone),
                      usageCount: coupon?.usageCount ?? 0,
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
                      emailRestrictions: emailRestrictions,
                      usedBy: coupon?.usedBy ?? [])
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

// MARK: - Helpers
//
private extension AddEditCouponViewModel {
    func checkDiscountTypeUpdated(for coupon: Coupon) -> Bool {
        guard let initialCoupon = self.coupon else {
            return false
        }
        return coupon.discountType != initialCoupon.discountType
    }

    func checkUsageRestrictionsOnCreation(of coupon: Coupon) -> Bool {
        coupon.maximumAmount.isNotEmpty ||
                coupon.minimumAmount.isNotEmpty ||
                (coupon.usageLimit ?? 0) > 0 ||
                (coupon.usageLimitPerUser ?? 0) > 0 ||
                (coupon.limitUsageToXItems ?? 0) > 0 ||
                coupon.emailRestrictions.isNotEmpty ||
                coupon.individualUse ||
                coupon.excludeSaleItems ||
                coupon.excludedProductIds.isNotEmpty ||
                coupon.excludedProductCategories.isNotEmpty
    }

    func checkUsageRestrictionsUpdated(for coupon: Coupon) -> Bool {
        guard let initialCoupon = self.coupon else {
            return false
        }
        let amountFormatter = CouponAmountInputFormatter()

        return amountFormatter.value(from: coupon.maximumAmount) != amountFormatter.value(from: initialCoupon.maximumAmount) ||
            amountFormatter.value(from: coupon.minimumAmount) != amountFormatter.value(from: initialCoupon.minimumAmount) ||
            coupon.usageLimit != initialCoupon.usageLimit ||
            coupon.usageLimitPerUser != initialCoupon.usageLimitPerUser ||
            coupon.limitUsageToXItems != initialCoupon.limitUsageToXItems ||
            coupon.emailRestrictions != initialCoupon.emailRestrictions ||
            coupon.individualUse != initialCoupon.individualUse ||
            coupon.excludeSaleItems != initialCoupon.excludeSaleItems ||
            coupon.excludedProductIds != initialCoupon.excludedProductIds ||
            coupon.excludedProductCategories != initialCoupon.excludedProductCategories
    }

    func checkExpiryDateUpdated(for coupon: Coupon) -> Bool {
        guard let initialCoupon = self.coupon else {
            return false
        }
        // since we're trimming time on the new date, we should also trim the time on the old date
        // as a workaround for the edge case where the date was created with different time zones.
        guard let oldDate = initialCoupon.dateExpires?.startOfDay(timezone: timezone),
              let newDate = coupon.dateExpires else {
            return initialCoupon.dateExpires != coupon.dateExpires
        }
        return !oldDate.isSameDay(as: newDate)
    }

    func checkCouponCodeUpdated(for coupon: Coupon) -> Bool {
        guard let initialCoupon = self.coupon else {
            return false
        }
        return coupon.code.lowercased() != initialCoupon.code.lowercased()
    }

    func checkAmountUpdated(for coupon: Coupon) -> Bool {
        guard let initialCoupon = self.coupon else {
            return false
        }
        let amountFormatter = CouponAmountInputFormatter()
        return amountFormatter.value(from: coupon.amount) != amountFormatter.value(from: initialCoupon.amount)
    }

    func checkDescriptionUpdated(for coupon: Coupon) -> Bool {
        guard let initialCoupon = self.coupon else {
            return false
        }
        return coupon.description != initialCoupon.description
    }

    func checkAllowedProductsAndCategoriesUpdated(for coupon: Coupon) -> Bool {
        guard let initialCoupon = self.coupon else {
            return false
        }
        return coupon.productIds != initialCoupon.productIds || coupon.productCategories != initialCoupon.productCategories
    }

    func checkFreeShippingUpdated(for coupon: Coupon) -> Bool {
        guard let initialCoupon = self.coupon else {
            return false
        }
        return coupon.freeShipping != initialCoupon.freeShipping
    }

    func trackCouponCreateInitiated(with coupon: Coupon) {
        ServiceLocator.analytics.track(.couponCreationInitiated, withProperties: [
            "discount_type": coupon.discountType.rawValue,
            "has_expiry_date": coupon.dateExpires != nil,
            "includes_free_shipping": coupon.freeShipping,
            "has_description": coupon.description.isNotEmpty,
            "has_product_or_category_restrictions": coupon.excludedProductCategories.isNotEmpty || coupon.excludedProductIds.isNotEmpty,
            "has_usage_restrictions": checkUsageRestrictionsOnCreation(of: coupon)
        ])
    }

    func trackCouponUpdateInitiated(with coupon: Coupon) {
        ServiceLocator.analytics.track(.couponUpdateInitiated, withProperties: [
            "discount_type_updated": checkDiscountTypeUpdated(for: coupon),
            "coupon_code_updated": checkCouponCodeUpdated(for: coupon),
            "amount_updated": checkAmountUpdated(for: coupon),
            "description_updated": checkDescriptionUpdated(for: coupon),
            "allowed_products_or_categories_updated": checkAllowedProductsAndCategoriesUpdated(for: coupon),
            "expiry_date_updated": checkExpiryDateUpdated(for: coupon),
            "usage_restrictions_updated": checkUsageRestrictionsUpdated(for: coupon)
        ])
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
        static let createCouponTitle = NSLocalizedString("Create coupon", comment: "Title of the Create coupon screen")
        static let editCouponTitle = NSLocalizedString("Edit coupon", comment: "Title of the Edit coupon screen")
        static let saveButton = NSLocalizedString("Save", comment: "Action for saving a Coupon remotely")
        static let createButton = NSLocalizedString("Create", comment: "Action for creating a Coupon remotely")
    }
}
