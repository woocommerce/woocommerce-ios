import Yosemite

private extension ProductType {
    /// Title shown on the action sheet.
    ///
    var actionSheetTitle: String {
        switch self {
        case .simple:
            return NSLocalizedString("Simple product",
                                     comment: "Action sheet option Simple when the user wants to change the Product type")
        case .variable:
            return NSLocalizedString("Variable product",
                                     comment: "Action sheet option Variable when the user wants to change the Product type")
        case .grouped:
            return NSLocalizedString("Grouped product",
                                     comment: "Action sheet option Grouped when the user wants to change the Product type")
        case .affiliate:
            return NSLocalizedString("External product",
                                     comment: "Action sheet option External when the user wants to change the Product type")
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
                                     comment: "Description of the Action sheet option  for the product type Simple")
        case .variable:
            return NSLocalizedString("A product with variations like color or size",
                                     comment: "Description of the Action sheet option  for the product type Variable")
        case .grouped:
            return NSLocalizedString("A collection of related products",
                                     comment: "Description of the Action sheet option  for the product type Grouped")
        case .affiliate:
            return NSLocalizedString("Link a product to an external website",
                                     comment: "Description of the Action sheet option  for the product type External")
        case .custom(let title):
            return title
        }
    }
}

/// `BottomSheetListSelectorCommand` for selecting a product type for the selected Product.
///
final class ProductTypeBottomSheetListSelectorCommand: BottomSheetListSelectorCommand {
    typealias Model = ProductType
    typealias Cell = ImageAndTitleAndTextTableViewCell

    let data: [ProductType] = [
        .simple,
        .variable,
        .grouped,
        .affiliate
    ]

    var selected: ProductType? = nil

    private let onSelection: (ProductType) -> Void

    init(onSelection: @escaping (ProductType) -> Void) {
        self.onSelection = onSelection
    }

    func configureCell(cell: ImageAndTitleAndTextTableViewCell, model: ProductType) {
        let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: model.actionSheetTitle,
                                                                    text: model.actionSheetDescription,
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
