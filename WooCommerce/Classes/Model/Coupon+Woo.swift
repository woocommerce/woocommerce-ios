import Foundation
import Yosemite
import UIKit

extension Coupon.DiscountType {
    /// Localized name to be displayed for the discount type.
    ///
    var localizedName: String {
        switch self {
        case .percent:
            return Localization.percentageDiscount
        case .fixedCart:
            return Localization.fixedCartDiscount
        case .fixedProduct:
            return Localization.fixedProductDiscount
        case .other:
            return Localization.otherDiscount
        }
    }

    private enum Localization {
        static let percentageDiscount = NSLocalizedString("Percentage Discount", comment: "Name of percentage discount type")
        static let fixedCartDiscount = NSLocalizedString("Fixed Cart Discount", comment: "Name of fixed cart discount type")
        static let fixedProductDiscount = NSLocalizedString("Fixed Product Discount", comment: "Name of fixed product discount type")
        static let otherDiscount = NSLocalizedString("Other", comment: "Generic name of non-default discount types")
        static let titleEditPercentageDiscount = NSLocalizedString(
            "Edit percentage discount",
            comment: "Title of the view for editing a coupon with percentage discount.")
        static let titleEditFixedCartDiscount = NSLocalizedString(
            "Edit fixed cart discount",
            comment: "Title of the view for editing a coupon with fixed cart discount.")
        static let titleEditFixedProductDiscount = NSLocalizedString(
            "Edit fixed product discount",
            comment: "Title of the view for editing a coupon with fixed product discount.")
        static let titleEditGenericDiscount = NSLocalizedString(
            "Edit discount",
            comment: "Title of the view for editing a coupon with generic discount.")
        static let titleCreatePercentageDiscount = NSLocalizedString(
            "Create percentage discount",
            comment: "Title of the view for creating a coupon with percentage discount.")
        static let titleCreateFixedCartDiscount = NSLocalizedString(
            "Create fixed cart discount",
            comment: "Title of the view for creating a coupon with fixed cart discount.")
        static let titleCreateFixedProductDiscount = NSLocalizedString(
            "Create fixed product discount",
            comment: "Title of the view for creating a coupon with fixed product discount.")
        static let titleCreateGenericDiscount = NSLocalizedString(
            "Create discount",
            comment: "Title of the view for creating a coupon with generic discount.")
    }
}

// MARK: - Coupon details
//
extension Coupon {

    /// Expiry status for Coupons.
    ///
    func expiryStatus(now: Date = Date()) -> ExpiryStatus {
        guard let expiryDate = dateExpires else {
            return .active
        }

        guard let gmtTimeZone = TimeZone(identifier: "GMT") else {
            return .expired
        }

        var calendar = Calendar.current
        calendar.timeZone = gmtTimeZone

        // Compare the dates by minute to get around edge cases of timezone differences.
        let result = calendar.compare(expiryDate, to: now, toGranularity: .minute)
        return result == .orderedDescending ? .active : .expired
    }

    /// Summary line for the coupon
    ///
    func summary(currencySettings: CurrencySettings = ServiceLocator.currencySettings) -> String {
        let amount = formattedAmount(currencySettings: currencySettings)
        let applyRules = localizeApplyRules(productsCount: productIds.count,
                                            excludedProductsCount: excludedProductIds.count,
                                            categoriesCount: productCategories.count,
                                            excludedCategoriesCount: excludedProductCategories.count)
        return amount.isEmpty ? applyRules : String.localizedStringWithFormat(Localization.summaryFormat, amount, applyRules)
    }

    /// Formatted amount for the coupon
    ///
    func formattedAmount(currencySettings: CurrencySettings) -> String {
        var amountString: String = ""
        switch discountType {
        case .percent:
            let percentFormatter = NumberFormatter()
            percentFormatter.numberStyle = .percent
            percentFormatter.maximumFractionDigits = 2
            percentFormatter.multiplier = 1
            percentFormatter.decimalSeparator = currencySettings.decimalSeparator
            if let amountDouble = Double(amount) {
                let amountNumber = NSNumber(value: amountDouble)
                amountString = percentFormatter.string(from: amountNumber) ?? ""
            }
        case .fixedCart, .fixedProduct:
            let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
            amountString = currencyFormatter.formatAmount(amount) ?? ""
        case .other:
            break // skip formatting for unsupported types
        }
        return amountString
    }

    /// Localize content for the "Apply to" field. This takes into consideration different cases of apply rules:
    ///    - When only specific products or categories are defined: Display "x Products" or "x Categories"
    ///    - When specific products/categories and exceptions are defined: Display "x Products excl. y Categories" etc.
    ///    - When both specific products and categories are defined: Display "x Products and y Categories"
    ///    - When only exceptions are defined: Display "All excl. x Products" or "All excl. y Categories"
    ///
    private func localizeApplyRules(productsCount: Int, excludedProductsCount: Int, categoriesCount: Int, excludedCategoriesCount: Int) -> String {
        let productText = String.pluralize(productsCount, singular: Localization.singleProduct, plural: Localization.multipleProducts)
        let productExceptionText = String.pluralize(excludedProductsCount, singular: Localization.singleProduct, plural: Localization.multipleProducts)
        let categoryText = String.pluralize(categoriesCount, singular: Localization.singleCategory, plural: Localization.multipleCategories)
        let categoryExceptionText = String.pluralize(excludedCategoriesCount, singular: Localization.singleCategory, plural: Localization.multipleCategories)

        switch (productsCount, excludedProductsCount, categoriesCount, excludedCategoriesCount) {
        case let (products, _, categories, _) where products > 0 && categories > 0:
            return String.localizedStringWithFormat(Localization.combinedRules, productText, categoryText)
        case let (products, excludedProducts, _, _) where products > 0 && excludedProducts > 0:
            return String.localizedStringWithFormat(Localization.ruleWithException, productText, productExceptionText)
        case let (products, _, _, excludedCategories) where products > 0 && excludedCategories > 0:
            return String.localizedStringWithFormat(Localization.ruleWithException, productText, categoryExceptionText)
        case let (products, _, _, _) where products > 0:
            return productText
        case let (_, excludedProducts, categories, _) where excludedProducts > 0 && categories > 0:
            return String.localizedStringWithFormat(Localization.ruleWithException, categoryText, productExceptionText)
        case let (_, _, categories, excludedCategories) where categories > 0 && excludedCategories > 0:
            return String.localizedStringWithFormat(Localization.ruleWithException, categoryText, categoryExceptionText)
        case let (_, _, categories, _) where categories > 0:
            return categoryText
        case let (_, excludedProducts, _, _) where excludedProducts > 0:
            return String.localizedStringWithFormat(Localization.allWithException, productExceptionText)
        case let (_, _, _, excludedCategories) where excludedCategories > 0:
            return String.localizedStringWithFormat(Localization.allWithException, categoryExceptionText)
        default:
            return Localization.allProducts
        }
    }
}

// MARK: - Subtypes
extension Coupon {
    /// Expiry status for coupons
    enum ExpiryStatus {
        case active
        case expired

        /// Localized name to be displayed for the expiry status.
        ///
        var localizedName: String {
            switch self {
            case .active:
                return Localization.active
            case .expired:
                return Localization.expired
            }
        }

        /// Text color for the expiry status label
        ///
        var statusForegroundColor: UIColor {
            .black
        }

        /// Background color for the expiry status label
        ///
        var statusBackgroundColor: UIColor {
            switch self {
            case .active:
                return .withColorStudio(.green, shade: .shade5)
            case .expired:
                return .gray(.shade5)
            }
        }

        private enum Localization {
            static let active = NSLocalizedString("Active", comment: "Status of coupons that are active")
            static let expired = NSLocalizedString("Expired", comment: "Status of coupons that are expired")
        }
    }

    private enum Localization {
        static let allProducts = NSLocalizedString(
            "All Products",
            comment: "Text indicating that there's no limit to the number of products that a coupon can be applied for. " +
            "Displayed on coupon list items and details screen"
        )
        static let singleProduct = NSLocalizedString(
            "%1$d Product",
            comment: "The number of products allowed for a coupon in singular form. Reads like: 1 Product"
        )
        static let multipleProducts = NSLocalizedString(
            "%1$d Products",
            comment: "The number of products allowed for a coupon in plural form. " +
            "Reads like: 10 Products"
        )
        static let singleCategory = NSLocalizedString(
            "%1$d Category",
            comment: "The number of category allowed for a coupon in singular form. Reads like: 1 Category"
        )
        static let multipleCategories = NSLocalizedString(
            "%1$d Categories",
            comment: "The number of category allowed for a coupon in plural form. " +
            "Reads like: 10 Categories"
        )
        static let summaryFormat = NSLocalizedString(
            "%1$@ off %2$@",
            comment: "Summary line for a coupon, with the discounted amount and number of products and categories that the coupon is limited to. " +
            "Reads like: '10% off all products' or '$15 off 2 Product 1 Category'"
        )
        static let allWithException = NSLocalizedString(
            "All Products excl. %1$@",
            comment: "Exception rule for a coupon. Reads like: All Products excl. 2 Products"
        )
        static let ruleWithException = NSLocalizedString(
            "%1$@ excl. %2$@",
            comment: "Exception rule for a coupon. Reads like: 3 Products excl. 1 Category"
        )
        static let combinedRules = NSLocalizedString(
            "%1$@, %2$@",
            comment: "Combined rule for a coupon. Reads like: 2 Products, 1 Category"
        )
    }
}

// MARK: - Sample Data
#if DEBUG
extension Coupon {
    static let sampleCoupon = Coupon(couponID: 720,
                                     code: "AGK32FD",
                                     amount: "10.00",
                                     dateCreated: Date(timeIntervalSinceNow: -1000),
                                     dateModified: Date(timeIntervalSinceNow: -1000),
                                     discountType: .fixedCart,
                                     description: "Coupon description",
                                     dateExpires: Date(timeIntervalSinceNow: 1000).startOfDay(timezone: TimeZone.current),
                                     usageCount: 10,
                                     individualUse: true,
                                     productIds: [],
                                     excludedProductIds: [12213],
                                     usageLimit: 1200,
                                     usageLimitPerUser: 3,
                                     limitUsageToXItems: 10,
                                     freeShipping: true,
                                     productCategories: [123, 435, 232],
                                     excludedProductCategories: [908],
                                     excludeSaleItems: false,
                                     minimumAmount: "5.00",
                                     maximumAmount: "500.00",
                                     emailRestrictions: ["*@a8c.com", "someone.else@example.com"],
                                     usedBy: ["someone.else@example.com", "person@a8c.com"])
}
#endif
