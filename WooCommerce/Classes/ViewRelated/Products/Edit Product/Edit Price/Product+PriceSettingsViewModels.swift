import Yosemite

extension Product {

    // Regex that match all the occurrences of the thousand separators.
    // All the points or comma (but not the last `.` or `,`)
    //
    private static let regexThousandSeparators = "(?:[.,](?=.*[.,])|)+"

    private static let placeholder = "0"

    static func createRegularPriceViewModel(regularPrice: String?,
                                            using currencySettings: CurrencySettings,
                                            onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Price", comment: "Title of the cell in Product Price Settings > Price")

        let currencyFormatter = CurrencyFormatter()
        let currencyCode = CurrencySettings.shared.currencyCode
        let unit = CurrencySettings.shared.symbol(from: currencyCode)
        let decimalValue = regularPrice.map { currencyFormatter.convertToDecimal(from: $0) ?? 0 }
        let value = decimalValue.map { "\($0)" } ?? ""
        return UnitInputViewModel(title: title,
                                  unit: unit,
                                  value: value,
                                  placeholder: placeholder,
                                  unitPosition: currencySettings.currencyUnitPosition,
                                  keyboardType: .decimalPad,
                                  inputFormatter: PriceInputFormatter(),
                                  onInputChange: onInputChange)
    }

    static func createSalePriceViewModel(salePrice: String?,
                                         using currencySettings: CurrencySettings,
                                         onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Sale price", comment: "Title of the cell in Product Price Settings > Sale price")

        let currencyFormatter = CurrencyFormatter()
        let currencyCode = CurrencySettings.shared.currencyCode
        let unit = CurrencySettings.shared.symbol(from: currencyCode)
        let decimalValue = salePrice.map { currencyFormatter.convertToDecimal(from: $0) ?? 0 }
        let value = decimalValue.map { "\($0)" } ?? ""
        return UnitInputViewModel(title: title,
                                  unit: unit,
                                  value: value,
                                  placeholder: placeholder,
                                  unitPosition: currencySettings.currencyUnitPosition,
                                  keyboardType: .decimalPad,
                                  inputFormatter: PriceInputFormatter(),
                                  onInputChange: onInputChange)
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
