import Yosemite

extension Product {
    static func createSKUViewModel(sku: String?, onTextChange: @escaping (_ text: String?) -> Void) -> TitleAndTextFieldTableViewCell.ViewModel {
        let title = NSLocalizedString("SKU", comment: "Title of the cell in Product Inventory Settings > SKU")
        let placeholder = NSLocalizedString("Optional",
                                            comment: "Placeholder of the cell text field in Product Inventory Settings > SKU")
        return TitleAndTextFieldTableViewCell.ViewModel(title: title,
                                                        text: sku,
                                                        placeholder: placeholder,
                                                        textFieldAlignment: .leading,
                                                        onTextChange: onTextChange)
    }

    static func createGlobalUniqueIdentifierViewModel(onTextChange: @escaping (_ text: String?) -> Void) -> TitleAndTextFieldTableViewCell.ViewModel {
        let title = NSLocalizedString("productInventorySettings.globalUniqueIdentifier.title",
                                      value: "GTIN, UPC, EAN, ISBN",
                                      comment: "Title of the cell in Product Inventory Settings > GTIN, UPC, EAN, or ISBN")
        let placeholder = NSLocalizedString("productInventorySettings.globalUniqueIdentifier.placeholder",
                                            value: "Optional",
                                            comment: "Placeholder of the cell in Product Inventory Settings > GTIN, UPC, EAN, or ISBN")
        return TitleAndTextFieldTableViewCell.ViewModel(title: title,
                                                        text: "",
                                                        placeholder: placeholder,
                                                        textFieldAlignment: .leading,
                                                        onTextChange: onTextChange)
    }

    static func createStockQuantityViewModel(stockQuantity: Decimal?, onInputChange: @escaping (_ input: String?) -> Void) -> UnitInputViewModel {
        let title = NSLocalizedString("Quantity", comment: "Title of the cell in Product Inventory Settings > Quantity")
        let stockQuantity = stockQuantity ?? 0
        let value = NumberFormatter.localizedString(from: stockQuantity as NSDecimalNumber, number: .decimal)
        let accessibilityHint = NSLocalizedString(
            "The stock quantity for this product. Editable.",
            comment: "VoiceOver accessibility hint, informing the user that the cell shows the stock quantity information for this product.")
        return UnitInputViewModel(title: title,
                                  unit: "",
                                  value: value,
                                  placeholder: "0",
                                  accessibilityHint: accessibilityHint,
                                  unitPosition: .none,
                                  keyboardType: .numberPad,
                                  inputFormatter: IntegerInputFormatter(),
                                  style: .primary,
                                  isInputEnabled: stockQuantity.isInteger,
                                  onInputChange: onInputChange)
    }
}
