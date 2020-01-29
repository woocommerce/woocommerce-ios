import Yosemite

extension Product {
    static func createShippingWeightViewModel(weight: String?,
                                              using shippingSettingsService: ShippingSettingsService,
                                              onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Weight", comment: "Title of the cell in Product Shipping Settings > Weight")
        let unit = shippingSettingsService.weightUnit ?? ""
        let value = weight == nil || weight?.isEmpty == true ? "": weight
        return UnitInputViewModel(title: title,
                                  unit: unit,
                                  value: value,
                                  placeholder: "0",
                                  keyboardType: .decimalPad,
                                  inputFormatter: ShippingInputFormatter(),
                                  onInputChange: onInputChange)
    }

    static func createShippingLengthViewModel(length: String,
                                              using shippingSettingsService: ShippingSettingsService,
                                              onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Length", comment: "Title of the cell in Product Shipping Settings > Length")
        let unit = shippingSettingsService.dimensionUnit ?? ""
        return UnitInputViewModel(title: title,
                                  unit: unit,
                                  value: length.isEmpty ? "": length,
                                  placeholder: "0",
                                  keyboardType: .decimalPad,
                                  inputFormatter: ShippingInputFormatter(),
                                  onInputChange: onInputChange)
    }

    static func createShippingWidthViewModel(width: String,
                                             using shippingSettingsService: ShippingSettingsService,
                                             onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Width", comment: "Title of the cell in Product Shipping Settings > Width")
        let unit = shippingSettingsService.dimensionUnit ?? ""
        return UnitInputViewModel(title: title,
                                  unit: unit,
                                  value: width.isEmpty ? "": width,
                                  placeholder: "0",
                                  keyboardType: .decimalPad,
                                  inputFormatter: ShippingInputFormatter(),
                                  onInputChange: onInputChange)
    }

    static func createShippingHeightViewModel(height: String,
                                              using shippingSettingsService: ShippingSettingsService,
                                              onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Height", comment: "Title of the cell in Product Shipping Settings > Height")
        let unit = shippingSettingsService.dimensionUnit ?? ""
        return UnitInputViewModel(title: title,
                                  unit: unit,
                                  value: height.isEmpty ? "": height,
                                  placeholder: "0",
                                  keyboardType: .decimalPad,
                                  inputFormatter: ShippingInputFormatter(),
                                  onInputChange: onInputChange)
    }
}
