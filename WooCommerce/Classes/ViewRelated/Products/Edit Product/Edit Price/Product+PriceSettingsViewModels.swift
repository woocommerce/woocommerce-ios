import Yosemite
import WooFoundation

extension Product {
    private static let placeholder = "0"

    static func createRegularPriceViewModel(regularPrice: String?,
                                            using currencySettings: CurrencySettings,
                                            onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
        let currencyCode = ServiceLocator.currencySettings.currencyCode
        let unit = ServiceLocator.currencySettings.symbol(from: currencyCode)
        let thousandsSeparator = ServiceLocator.currencySettings.groupingSeparator
        let value: String = {
            guard let regularPrice, regularPrice.isNotEmpty else {
                return ""
            }
            return (currencyFormatter.formatAmount(regularPrice, with: unit) ?? "")
                .replacingOccurrences(of: unit, with: "")
                .replacingOccurrences(of: thousandsSeparator, with: "")
                .filter { !$0.isWhitespace }
        }()
        return UnitInputViewModel(title: Localization.regularPriceTitle,
                                  unit: unit,
                                  value: value,
                                  placeholder: placeholder,
                                  accessibilityHint: Localization.regularPriceAccessibilityHint,
                                  unitPosition: currencySettings.currencyUnitPosition,
                                  keyboardType: .numbersAndPunctuation,
                                  inputFormatter: PriceInputFormatter(),
                                  style: .primary,
                                  onInputChange: onInputChange)
    }

    static func createSalePriceViewModel(salePrice: String?,
                                         using currencySettings: CurrencySettings,
                                         onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
        let currencyCode = ServiceLocator.currencySettings.currencyCode
        let unit = ServiceLocator.currencySettings.symbol(from: currencyCode)
        let thousandsSeparator = ServiceLocator.currencySettings.groupingSeparator
        let value: String = {
            guard let salePrice, salePrice.isNotEmpty else {
                return ""
            }
            return (currencyFormatter.formatAmount(salePrice, with: unit) ?? "")
                .replacingOccurrences(of: unit, with: "")
                .replacingOccurrences(of: thousandsSeparator, with: "")
                .filter { !$0.isWhitespace }
        }()

        return UnitInputViewModel(title: Localization.salePriceTitle,
                                  unit: unit,
                                  value: value,
                                  placeholder: placeholder,
                                  accessibilityHint: Localization.salePriceAccessibility,
                                  unitPosition: currencySettings.currencyUnitPosition,
                                  keyboardType: .numbersAndPunctuation,
                                  inputFormatter: PriceInputFormatter(),
                                  style: .primary,
                                  onInputChange: onInputChange)
    }

    static func createSubscriptionSignupFeeViewModel(fee: String?,
                                                     using currencySettings: CurrencySettings,
                                                     onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
        let currencyCode = ServiceLocator.currencySettings.currencyCode
        let unit = ServiceLocator.currencySettings.symbol(from: currencyCode)
        let thousandsSeparator = ServiceLocator.currencySettings.groupingSeparator
        let value: String = {
            guard let fee, fee.isNotEmpty else {
                return ""
            }
            return (currencyFormatter.formatAmount(fee, with: unit) ?? "")
                .replacingOccurrences(of: unit, with: "")
                .replacingOccurrences(of: thousandsSeparator, with: "")
                .filter { !$0.isWhitespace }
        }()
        return UnitInputViewModel(title: Localization.signupFeeTitle,
                                  subtitle: Localization.signupFeeSubtitle,
                                  unit: unit,
                                  value: value,
                                  placeholder: placeholder,
                                  accessibilityHint: Localization.signupFeeAccessibilityHint,
                                  unitPosition: currencySettings.currencyUnitPosition,
                                  keyboardType: .numbersAndPunctuation,
                                  inputFormatter: PriceInputFormatter(),
                                  style: .primary,
                                  onInputChange: onInputChange)
    }

    private enum Localization {
        static let regularPriceTitle = NSLocalizedString(
            "productPriceSettingsViewModel.regularPriceTitle",
            value: "Price",
            comment: "Title of the cell in Product Price Settings > Price"
        )
        static let regularPriceAccessibilityHint = NSLocalizedString(
            "productPriceSettingsViewModel.regularPriceAccessibilityHint",
            value: "The price for this product. Editable.",
            comment: "VoiceOver accessibility hint, informing the user that the cell shows the price information for this product."
        )
        static let salePriceTitle = NSLocalizedString(
            "productPriceSettingsViewModel.salePriceTitle",
            value: "Sale price",
            comment: "Title of the cell in Product Price Settings > Sale price"
        )
        static let salePriceAccessibility = NSLocalizedString(
            "productPriceSettingsViewModel.salePriceAccessibilityHint",
            value: "The sale price for this product. Editable.",
            comment: "VoiceOver accessibility hint, informing the user that the cell shows the sale price information for this product."
        )
        static let signupFeeTitle = NSLocalizedString(
            "productPriceSettingsViewModel.signupFeeTitle",
            value: "Sign-up Fee",
            comment: "Title of the cell in Product Price Settings > Sign-up Fee"
        )
        static let signupFeeSubtitle = NSLocalizedString(
            "productPriceSettingsViewModel.signupFeeSubtitle",
            value: "Optionally include an amount to be charged at the outset of the subscription. " +
            "The sign-up fee will be charged immediately, even if the product has a free trial or the payment dates are synced.",
            comment: "Subtitle of the cell in Product Price Settings > Sign-up Fee"
        )
        static let signupFeeAccessibilityHint = NSLocalizedString(
            "productPriceSettingsViewModel.signupFeeAccessibilityHint",
            value: "The subscription sign-up fee for this product. Editable.",
            comment: "VoiceOver accessibility hint, informing the user that the cell shows the subscription sign-up fee for this product."
        )
    }
}

private extension CurrencySettings {
    var currencyUnitPosition: UnitInputViewModel.UnitPosition {
        switch currencyPosition {
        case .left:
            return .beforeInputWithoutSpace
        case .leftSpace:
            return .beforeInput
        case .right:
            return .afterInputWithoutSpace
        case .rightSpace:
            return .afterInput
        }
    }
}
