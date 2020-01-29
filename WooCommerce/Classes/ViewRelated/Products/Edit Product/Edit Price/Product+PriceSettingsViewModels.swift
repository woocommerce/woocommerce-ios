import Yosemite

extension Product {
    static func createRegularPriceViewModel(regularPrice: String?,
                                            using currencySettings: CurrencySettings,
                                       onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Price", comment: "Title of the cell in Product Price Settings > Price")

        let currencyFormatter = CurrencyFormatter()
        let currencyCode = CurrencySettings.shared.currencyCode
        let unit = CurrencySettings.shared.symbol(from: currencyCode)
        var value = currencyFormatter.formatAmount(regularPrice ?? "", with: unit) ?? ""
        value = value.replacingOccurrences(of: unit, with: "")
        return UnitInputViewModel(title: title,
                                  unit: unit,
                                  value: value,
                                  placeholder: "0",
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
        var value = currencyFormatter.formatAmount(salePrice ?? "", with: unit) ?? ""
        value = value.replacingOccurrences(of: unit, with: "")
        return UnitInputViewModel(title: title,
                                  unit: unit,
                                  value: value,
                                  placeholder: "0",
                                  keyboardType: .decimalPad,
                                  inputFormatter: PriceInputFormatter(),
                                  onInputChange: onInputChange)
    }
}
