import Yosemite

private extension ProductType {
    /// Title shown on the action sheet.
    ///
    var actionSheetTitle: String {
        switch self {
        case .simple:
            return NSLocalizedString("Simple product",
                                     comment: "Action sheet option when the user wants to change the Product type to simple product")
        case .variable:
            return NSLocalizedString("Variable product",
                                     comment: "Action sheet option when the user wants to change the Product type to varible product")
        case .grouped:
            return NSLocalizedString("Grouped product",
                                     comment: "Action sheet option when the user wants to change the Product type to grouped product")
        case .affiliate:
            return NSLocalizedString("External product",
                                     comment: "Action sheet option when the user wants to change the Product type to external product")
        case .custom(let title):
            return title
        }
    }

    /// Description shown on the action sheet.
    ///
    var actionSheetDescription: String {
        switch self {
        case .simple:
            return NSLocalizedString("A unique item to sell",
                                     comment: "Description of the Action sheet option when the user wants to change the Product type to simple product")
        case .variable:
            return NSLocalizedString("A product with variations like color or size",
                                     comment: "Description of the Action sheet option when the user wants to change the Product type to variable product")
        case .grouped:
            return NSLocalizedString("A collection of related products",
                                     comment: "Description of the Action sheet option when the user wants to change the Product type to grouped product")
        case .affiliate:
            return NSLocalizedString("Link a product to an external website",
                                     comment: "Description of the Action sheet option when the user wants to change the Product type to external product")
        case .custom(let title):
            return title
        }
    }

    /// Image shown on the action sheet.
    ///
    var actionSheetImage: UIImage {
        switch self {
        case .simple:
            return UIImage.productImage
        case .variable:
            return UIImage.variationsImage
        case .grouped:
            return UIImage.widgetsImage
        case .affiliate:
            return UIImage.externalProductImage
        case .custom:
            return UIImage.productImage
        }
    }
}

/// `BottomSheetListSelectorCommand` for selecting a product type for the selected Product.
///
final class ProductTypeBottomSheetListSelectorCommand: BottomSheetListSelectorCommand {
    typealias Model = ProductType
    typealias Cell = ImageAndTitleAndTextTableViewCell

    var data: [ProductType] = [
        .simple,
        .variable,
        .grouped,
        .affiliate
    ]

    var selected: ProductType? = nil

    private let onSelection: (ProductType) -> Void

    init(selected: ProductType?, onSelection: @escaping (ProductType) -> Void) {
        self.onSelection = onSelection

        /// Remove from `data` the selected product type, so that it is not shown in the list.
        data.removeAll { (productType) -> Bool in
            productType == selected
        }
    }

    func configureCell(cell: ImageAndTitleAndTextTableViewCell, model: ProductType) {
        let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: model.actionSheetTitle,
                                                                    text: model.actionSheetDescription,
                                                                    image: model.actionSheetImage,
                                                                    imageTintColor: .gray(.shade20),
                                                                    numberOfLinesForText: 0,
                                                                    isActionable: false)
        cell.updateUI(viewModel: viewModel)
    }

    func handleSelectedChange(selected: ProductType) {
        onSelection(selected)
    }

    func isSelected(model: ProductType) -> Bool {
        return model == selected
    }
}
