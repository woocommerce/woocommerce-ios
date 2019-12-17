import Yosemite

extension Product {
    func createRegularPriceViewModel(using currencySettings: CurrencySettings,
                                       onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Price", comment: "Title of the cell in Product Price Settings > Price")
        let unit = currencySettings.currencyCode.rawValue
        let value = regularPrice == nil || regularPrice?.isEmpty == true ? "0": regularPrice
        return UnitInputViewModel(title: title,
                                  unit: unit,
                                  value: value,
                                  inputFormatter: DecimalInputFormatter(),
                                  onInputChange: onInputChange)
    }

    func createSalePriceViewModel(using currencySettings: CurrencySettings,
                                       onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Sale price", comment: "Title of the cell in Product Price Settings > Sale price")
        let unit = currencySettings.currencyCode.rawValue
        let value = salePrice == nil || salePrice?.isEmpty == true ? "0": salePrice
        return UnitInputViewModel(title: title,
                                  unit: unit,
                                  value: value,
                                  inputFormatter: DecimalInputFormatter(),
                                  onInputChange: onInputChange)
    }
}
