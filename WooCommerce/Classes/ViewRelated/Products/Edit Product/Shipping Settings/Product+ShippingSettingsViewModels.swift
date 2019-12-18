import Yosemite

extension Product {
    func createShippingWeightViewModel(using shippingSettingsService: ShippingSettingsService,
                                       onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Weight", comment: "Title of the cell in Product Shipping Settings > Weight")
        let unit = shippingSettingsService.weightUnit ?? ""
        let value = weight == nil || weight?.isEmpty == true ? "0": weight
        return UnitInputViewModel(title: title,
                                  unit: unit,
                                  value: value,
                                  keyboardType: .decimalPad,
                                  inputFormatter: DecimalInputFormatter(),
                                  onInputChange: onInputChange)
    }

    func createShippingLengthViewModel(using shippingSettingsService: ShippingSettingsService,
                                       onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Length", comment: "Title of the cell in Product Shipping Settings > Length")
        let unit = shippingSettingsService.dimensionUnit ?? ""
        return UnitInputViewModel(title: title,
                                  unit: unit,
                                  value: dimensions.length.isEmpty ? "0": dimensions.length,
                                  keyboardType: .decimalPad,
                                  inputFormatter: DecimalInputFormatter(),
                                  onInputChange: onInputChange)
    }

    func createShippingWidthViewModel(using shippingSettingsService: ShippingSettingsService,
                                      onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Width", comment: "Title of the cell in Product Shipping Settings > Width")
        let unit = shippingSettingsService.dimensionUnit ?? ""
        return UnitInputViewModel(title: title,
                                  unit: unit,
                                  value: dimensions.width.isEmpty ? "0": dimensions.width,
                                  keyboardType: .decimalPad,
                                  inputFormatter: DecimalInputFormatter(),
                                  onInputChange: onInputChange)
    }

    func createShippingHeightViewModel(using shippingSettingsService: ShippingSettingsService,
                                       onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Height", comment: "Title of the cell in Product Shipping Settings > Height")
        let unit = shippingSettingsService.dimensionUnit ?? ""
        return UnitInputViewModel(title: title,
                                  unit: unit,
                                  value: dimensions.height.isEmpty ? "0": dimensions.height,
                                  keyboardType: .decimalPad,
                                  inputFormatter: DecimalInputFormatter(),
                                  onInputChange: onInputChange)
    }
}
