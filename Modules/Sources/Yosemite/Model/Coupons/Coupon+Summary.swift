import Foundation
import UIKit
import WooFoundation

public extension Coupon {
    /// Summary line for the coupon
    ///
    func summary(currencySettings: CurrencySettings) -> String {
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
        let productText = productsCount == 1 ?
            String.localizedStringWithFormat(Localization.singleProduct, productsCount) :
            String.localizedStringWithFormat(Localization.multipleProducts, productsCount)

        let productExceptionText = excludedProductsCount == 1 ?
            String.localizedStringWithFormat(Localization.singleProduct, excludedProductsCount) :
            String.localizedStringWithFormat(Localization.multipleProducts, excludedProductsCount)

        let categoryText = categoriesCount == 1 ?
            String.localizedStringWithFormat(Localization.singleCategory, categoriesCount) :
            String.localizedStringWithFormat(Localization.multipleCategories, categoriesCount)

        let categoryExceptionText = excludedCategoriesCount == 1 ?
            String.localizedStringWithFormat(Localization.singleCategory, excludedCategoriesCount) :
            String.localizedStringWithFormat(Localization.multipleCategories, excludedCategoriesCount)

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
            "%1$@ off · %2$@",
            comment: "Summary line for a coupon, with the discounted amount and number of products and categories that the coupon is limited to. " +
            "Reads like: '10% off · all products' or '$15 off · 2 Product 1 Category'"
        )
        static let allWithException = NSLocalizedString(
            "All Products · Excl. %1$@",
            comment: "Exception rule for a coupon. Reads like: All Products · Excl. 2 Products"
        )
        static let ruleWithException = NSLocalizedString(
            "%1$@ · Excl. %2$@",
            comment: "Exception rule for a coupon. Reads like: 3 Products · Excl. 1 Category"
        )
        static let combinedRules = NSLocalizedString(
            "%1$@, %2$@",
            comment: "Combined rule for a coupon. Reads like: 2 Products, 1 Category"
        )
    }
}
