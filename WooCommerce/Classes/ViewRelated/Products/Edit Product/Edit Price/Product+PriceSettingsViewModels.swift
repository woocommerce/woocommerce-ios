import Foundation
import Yosemite
import WooFoundation

extension Product {
    private static let placeholder = "0"

    static func createRegularPriceViewModel(regularPrice: String?,
                                            using currencySettings: CurrencySettings,
                                            onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        let currencyCode = currencySettings.currencyCode
        let unit = currencySettings.symbol(from: currencyCode)
        let thousandsSeparator = currencySettings.groupingSeparator
        let value: String = {
            guard let regularPrice, regularPrice.isNotEmpty else {
                return ""
            }
            return (currencyFormatter.formatAmount(regularPrice, with: currencyCode.rawValue) ?? "")
                .replacingOccurrences(of: unit, with: "")
                .replacingOccurrences(of: thousandsSeparator, with: "")
                .filter { !$0.isWhitespace }
        }()
        return UnitInputViewModel(title: Localization.regularPriceTitle,
                                  unit: unit,
                                  value: value,
                                  placeholder: placeholder,
                                  accessibilityHint: Localization.regularPriceAccessibilityHint,
                                  unitPosition: currencySettings.priceInputUnitPosition,
                                  keyboardType: .numbersAndPunctuation,
                                  inputFormatter: PriceInputFormatter(),
                                  style: .primary,
                                  onInputChange: onInputChange)
    }

    static func createSalePriceViewModel(salePrice: String?,
                                         using currencySettings: CurrencySettings,
                                         onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        let currencyCode = currencySettings.currencyCode
        let unit = currencySettings.symbol(from: currencyCode)
        let thousandsSeparator = currencySettings.groupingSeparator
        let value: String = {
            guard let salePrice, salePrice.isNotEmpty else {
                return ""
            }
            return (currencyFormatter.formatAmount(salePrice, with: currencyCode.rawValue) ?? "")
                .replacingOccurrences(of: unit, with: "")
                .replacingOccurrences(of: thousandsSeparator, with: "")
                .filter { !$0.isWhitespace }
        }()

        return UnitInputViewModel(title: Localization.salePriceTitle,
                                  unit: unit,
                                  value: value,
                                  placeholder: placeholder,
                                  accessibilityHint: Localization.salePriceAccessibility,
                                  unitPosition: currencySettings.priceInputUnitPosition,
                                  keyboardType: .numbersAndPunctuation,
                                  inputFormatter: PriceInputFormatter(),
                                  style: .primary,
                                  onInputChange: onInputChange)
    }

    static func createSubscriptionSignupFeeViewModel(fee: String?,
                                                     using currencySettings: CurrencySettings,
                                                     onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        let currencyCode = currencySettings.currencyCode
        let unit = currencySettings.symbol(from: currencyCode)
        let thousandsSeparator = currencySettings.groupingSeparator
        let value: String = {
            guard let fee, fee.isNotEmpty else {
                return ""
            }
            return (currencyFormatter.formatAmount(fee, with: currencyCode.rawValue) ?? "")
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
                                  unitPosition: currencySettings.priceInputUnitPosition,
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

extension CurrencySettings {
    /// The placement of the currency symbol in price input fields.
    ///
    /// Price inputs render the amount and currency symbol in separate views, so Unicode bidirectional reordering
    /// cannot move a strong RTL currency symbol to the same visual side as formatted display strings.
    var priceInputUnitPosition: UnitInputViewModel.UnitPosition {
        switch (currencyPosition, currencySymbol.containsStrongRightToLeftCharacter) {
        case (.left, false), (.right, true):
            return .beforeInputWithoutSpace
        case (.leftSpace, false), (.rightSpace, true):
            return .beforeInput
        case (.right, false), (.left, true):
            return .afterInputWithoutSpace
        case (.rightSpace, false), (.leftSpace, true):
            return .afterInput
        }
    }
}

private extension String {
    var containsStrongRightToLeftCharacter: Bool {
        unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x0590...0x08FF, 0xFB1D...0xFDFF, 0xFE70...0xFEFF:
                return true
            default:
                return false
            }
        }
    }
}
