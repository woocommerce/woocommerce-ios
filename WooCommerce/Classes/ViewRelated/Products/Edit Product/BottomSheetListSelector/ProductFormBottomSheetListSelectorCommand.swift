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
         isEditProductsRelease2Enabled: Bool,
         isEditProductsRelease3Enabled: Bool, onSelection: @escaping (ProductFormBottomSheetAction) -> Void) {
        self.onSelection = onSelection

        let shouldShowShippingSettingsRow = product.isShippingEnabled
        let shouldShowBriefDescriptionRow = isEditProductsRelease2Enabled
        let shouldShowCategoriesRow = isEditProductsRelease3Enabled
        let actions: [ProductFormBottomSheetAction?] = [
            .editInventorySettings,
            shouldShowShippingSettingsRow ? .editShippingSettings: nil,
            shouldShowCategoriesRow ? .editCategories: nil,
            shouldShowBriefDescriptionRow ? .editBriefDescription: nil]
        self.data = actions.compactMap({ $0 })
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
