import Yosemite

extension Product {
    static func createSKUViewModel(sku: String?, onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("SKU", comment: "Title of the cell in Product Inventory Settings > SKU")
        return UnitInputViewModel(title: title,
                                  unit: "",
                                  value: sku,
                                  keyboardType: .default,
                                  inputFormatter: StringInputFormatter(),
                                  onInputChange: onInputChange)
    }

    static func createStockQuantityViewModel(stockQuantity: Int?, onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Quantity", comment: "Title of the cell in Product Inventory Settings > Quantity")
        return UnitInputViewModel(title: title,
                                  unit: "",
                                  value: "\(stockQuantity ?? 0)",
                                  keyboardType: .numberPad,
                                  inputFormatter: IntegerInputFormatter(),
                                  onInputChange: onInputChange)
    }
}
