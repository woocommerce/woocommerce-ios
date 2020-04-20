import Yosemite

/// `BottomSheetListSelectorDataSource` for selecting a sort order for the Products tab.
///
struct ProductsSortOrderBottomSheetListSelectorDataSource: BottomSheetListSelectorDataSource {
    typealias Model = ProductsSortOrder
    typealias Cell = BasicTableViewCell

    let data: [ProductsSortOrder] = [
        .dateDescending,
        .dateAscending,
        .nameDescending,
        .nameAscending
    ]

    var selected: ProductsSortOrder?

    init(selected: ProductsSortOrder?) {
        self.selected = selected
    }

    func configureCell(cell: BasicTableViewCell, model: ProductsSortOrder) {
        cell.selectionStyle = .default
        cell.textLabel?.text = model.actionSheetTitle
        cell.accessoryType = isSelected(model: model) ? .checkmark: .none
    }

    mutating func handleSelectedChange(selected: ProductsSortOrder) {
        self.selected = selected
    }

    func isSelected(model: ProductsSortOrder) -> Bool {
        return model == selected
    }
}
