import Yosemite

public enum BottomSheetOrderType: Hashable {
    case quick
    case full

    /// Title shown on the action sheet.
    ///
    var actionSheetTitle: String {
        switch self {
        case .full:
            return NSLocalizedString("Create order",
                                     comment: "Action sheet option when the user wants to create full manual order")
        case .quick:
            return NSLocalizedString("Quick order",
                                     comment: "Action sheet option when the user wants to create quick order")
        }
    }

    /// Description shown on the action sheet.
    ///
    var actionSheetDescription: String {
        switch self {
        case .full:
            return NSLocalizedString("Create a new manual order",
                                     comment: "Description of the Action sheet option when the user wants to create full manual order")
        case .quick:
            return NSLocalizedString("Create an order with minimal information",
                                     comment: "Description of the Action sheet option when the user wants to create quick order")
        }
    }

    /// Image shown on the action sheet.
    ///
    var actionSheetImage: UIImage {
        switch self {
        case .quick:
            return UIImage.pagesImage
        case .full:
            return UIImage.pagesImage
        }
    }
}

final class OrderTypeBottomSheetListSelectorCommand: BottomSheetListSelectorCommand {
    typealias Model = BottomSheetOrderType
    typealias Cell = ImageAndTitleAndTextTableViewCell

    var data: [BottomSheetOrderType] = [
        .full,
        .quick
    ]

    var selected: BottomSheetOrderType? = nil

    private let onSelection: (BottomSheetOrderType) -> Void

    init(selected: BottomSheetOrderType?, onSelection: @escaping (BottomSheetOrderType) -> Void) {
        self.onSelection = onSelection

        /// Remove from `data` the selected product type, so that it is not shown in the list.
        data.removeAll { (productType) -> Bool in
            productType == selected
        }
    }

    func configureCell(cell: ImageAndTitleAndTextTableViewCell, model: BottomSheetOrderType) {
        let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: model.actionSheetTitle,
                                                                    text: model.actionSheetDescription,
                                                                    image: model.actionSheetImage,
                                                                    imageTintColor: .gray(.shade20),
                                                                    numberOfLinesForText: 0,
                                                                    isActionable: false)
        cell.updateUI(viewModel: viewModel)
    }

    func handleSelectedChange(selected: BottomSheetOrderType) {
        onSelection(selected)
    }

    func isSelected(model: BottomSheetOrderType) -> Bool {
        return model == selected
    }
}
