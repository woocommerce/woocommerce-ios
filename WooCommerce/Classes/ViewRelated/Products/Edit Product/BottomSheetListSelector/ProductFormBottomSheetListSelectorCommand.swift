import Yosemite

/// `BottomSheetListSelectorCommand` for selecting a Product form action.
///
final class ProductFormBottomSheetListSelectorCommand: BottomSheetListSelectorCommand {
    typealias Model = ProductFormBottomSheetAction
    typealias Cell = ImageAndTitleAndTextTableViewCell

    let data: [ProductFormBottomSheetAction]

    let selected: ProductFormBottomSheetAction? = nil

    private let onSelection: (ProductFormBottomSheetAction) -> Void

    init(actions: [ProductFormBottomSheetAction],
         onSelection: @escaping (ProductFormBottomSheetAction) -> Void) {
        self.onSelection = onSelection
        self.data = actions
    }

    func configureCell(cell: ImageAndTitleAndTextTableViewCell, model: ProductFormBottomSheetAction) {
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator
        let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: model.title, text: model.subtitle)
        cell.updateUI(viewModel: viewModel)
    }

    func handleSelectedChange(selected: ProductFormBottomSheetAction) {
        onSelection(selected)
    }

    func isSelected(model: ProductFormBottomSheetAction) -> Bool {
        return model == selected
    }
}
