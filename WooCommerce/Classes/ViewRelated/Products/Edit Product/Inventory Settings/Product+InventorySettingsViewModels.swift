import Yosemite

extension Product {
    static func createSKUViewModel(sku: String?, onTextChange: @escaping (_ text: String?) -> Void) -> TitleAndTextFieldTableViewCell.ViewModel {
        let title = NSLocalizedString("SKU", comment: "Title of the cell in Product Inventory Settings > SKU")
        let placeholder = NSLocalizedString("Optional",
                                            comment: "Placeholder of the cell text field in Product Inventory Settings > SKU")
        return TitleAndTextFieldTableViewCell.ViewModel(title: title,
                                                        text: sku,
                                                        placeholder: placeholder,
                                                        onTextChange: onTextChange)
    }

    static func createStockQuantityViewModel(stockQuantity: Int?, onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Quantity", comment: "Title of the cell in Product Inventory Settings > Quantity")
        return UnitInputViewModel(title: title,
                                  unit: "",
                                  value: "\(stockQuantity ?? 0)",
                                  placeholder: "0",
                                  keyboardType: .numberPad,
                                  inputFormatter: IntegerInputFormatter(),
                                  onInputChange: onInputChange)
    }
}
