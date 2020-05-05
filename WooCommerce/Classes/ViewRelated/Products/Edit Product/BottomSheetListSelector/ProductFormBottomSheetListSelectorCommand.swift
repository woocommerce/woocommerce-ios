import Yosemite

/// `BottomSheetListSelectorCommand` for selecting a Product form action.
///
final class ProductFormBottomSheetListSelectorCommand: BottomSheetListSelectorCommand {
    typealias Model = ProductFormBottomSheetAction
    typealias Cell = ImageAndTitleAndTextTableViewCell

    let data: [ProductFormBottomSheetAction]

    let selected: ProductFormBottomSheetAction? = nil

    private let onSelection: (ProductFormBottomSheetAction) -> Void

    init(product: Product,
         isEditProductsRelease3Enabled: Bool,
         onSelection: @escaping (ProductFormBottomSheetAction) -> Void) {
        self.onSelection = onSelection

        let shouldShowShippingSettingsRow = product.isShippingEnabled
        let shouldShowCategoriesRow = isEditProductsRelease3Enabled
        let actions: [ProductFormBottomSheetAction?] = [
            .editInventorySettings,
            shouldShowShippingSettingsRow ? .editShippingSettings: nil,
            shouldShowCategoriesRow ? .editCategories: nil,
            .editBriefDescription
        ]
        self.data = actions.compactMap({ $0 }).filter({ $0.isVisible(product: product) })
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
