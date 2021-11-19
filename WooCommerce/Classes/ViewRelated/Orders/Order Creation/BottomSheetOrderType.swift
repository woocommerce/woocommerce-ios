import Yosemite

public enum BottomSheetOrderType: Hashable {
    case simple
    case full

    /// Title shown on the action sheet.
    ///
    var actionSheetTitle: String {
        switch self {
        case .simple:
            return NSLocalizedString("Simple Payments",
                                     comment: "Action sheet option when the user wants to create Simple Payments order")
        case .full:
            return NSLocalizedString("Create order",
                                     comment: "Action sheet option when the user wants to create full manual order")
        }
    }

    /// Description shown on the action sheet.
    ///
    var actionSheetDescription: String {
        switch self {
        case .simple:
            return NSLocalizedString("Create an order with minimal information",
                                     comment: "Description of the Action sheet option when the user wants to create Simple Payments order")
        case .full:
            return NSLocalizedString("Create a new manual order",
                                     comment: "Description of the Action sheet option when the user wants to create full manual order")
        }
    }

    /// Image shown on the action sheet.
    ///
    var actionSheetImage: UIImage {
        switch self {
        case .simple:
            return UIImage.simplePaymentsImage
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
        .simple
    ]

    var selected: BottomSheetOrderType? = nil

    private let onSelection: (BottomSheetOrderType) -> Void

    init(onSelection: @escaping (BottomSheetOrderType) -> Void) {
        self.onSelection = onSelection
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
}
