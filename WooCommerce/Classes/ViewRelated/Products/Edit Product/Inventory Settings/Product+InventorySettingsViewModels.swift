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
        let value = "\(stockQuantity ?? 0)"

        return UnitInputViewModel(title: title,
                                  unit: "",
                                  value: value,
                                  placeholder: "0",
                                  accessibilityHint: NSLocalizedString(
                                  "The stock quantity for this product. Editable.",
                                  comment: "VoiceOver accessibility hint, informing the user that the cell shows the stock quantity information for this product."),
                                  unitPosition: .none,
                                  keyboardType: .numberPad,
                                  inputFormatter: IntegerInputFormatter(),
                                  onInputChange: onInputChange)
    }
}
