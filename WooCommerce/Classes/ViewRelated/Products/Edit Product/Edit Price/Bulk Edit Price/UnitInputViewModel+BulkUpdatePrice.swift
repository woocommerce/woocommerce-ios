import Foundation

extension UnitInputViewModel {
    /// Creates a `UnitInputViewModel` for configuring the cell for the bulk price update.
    /// It has the price input field on the left and no title (`.secondary` style).
    ///
    static func createBulkPriceViewModel(using currencySettings: CurrencySettings,
                                         onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {

        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        let currencyCode = currencySettings.currencyCode
        let unit = currencySettings.symbol(from: currencyCode)
        /// Depending on the currency settings we might have different decimal seperator or number of digits
        let formattedPlaceholder = currencyFormatter.localize(Decimal.zero,
                                                              with: currencySettings.decimalSeparator,
                                                              in: currencySettings.numberOfDecimals,
                                                              including: currencySettings.thousandSeparator)
        return UnitInputViewModel(title: "",
                                  unit: unit,
                                  value: nil,
                                  placeholder: formattedPlaceholder,
                                  accessibilityHint: NSLocalizedString(
                                    "The price for bulk updating all variations. Editable.",
                                    comment: "VoiceOver accessibility hint, informing the user that this field allows to enter the price to use for"
                                    + " bulk updating all variations"),
                                  unitPosition: currencySettings.currencyUnitPosition,
                                  keyboardType: .decimalPad,
                                  inputFormatter: PriceInputFormatter(),
                                  style: .secondary,
                                  onInputChange: onInputChange)
    }
}

private extension CurrencySettings {
    /// The placement of the currency symbol accordig to the currency settings
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
