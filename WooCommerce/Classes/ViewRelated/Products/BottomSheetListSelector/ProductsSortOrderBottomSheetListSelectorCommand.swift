import Yosemite

private extension ProductsSortOrder {
    /// Title shown on the action sheet.
    ///
    var actionSheetTitle: String {
        switch self {
        case .dateAscending:
            return NSLocalizedString("Date: Oldest to Newest", comment: "Action sheet option to sort products from the oldest to the newest")
        case .dateDescending:
            return NSLocalizedString("Date: Newest to Oldest", comment: "Action sheet option to sort products from the newest to the oldest")
        case .nameAscending:
            return NSLocalizedString("Title: A to Z", comment: "Action sheet option to sort products by ascending product name")
        case .nameDescending:
            return NSLocalizedString("Title: Z to A", comment: "Action sheet option to sort products by descending product name")
        }
    }
}

/// `BottomSheetListSelectorCommand` for selecting a sort order for the Products tab.
///
struct ProductsSortOrderBottomSheetListSelectorCommand: BottomSheetListSelectorCommand {
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
