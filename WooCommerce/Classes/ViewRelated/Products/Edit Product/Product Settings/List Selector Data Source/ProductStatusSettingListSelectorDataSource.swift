import UIKit
import Yosemite

/// `ListSelectorDataSource` for selecting a Product Status Setting.
///
struct ProductStatusSettingListSelectorDataSource: ListSelectorDataSource {
    typealias Model = ProductStatus
    typealias Cell = BasicTableViewCell

    let data: [ProductStatus] = [
        .publish,
        .draft,
        .pending,
        .privateStatus
    ]

    private(set) var selected: ProductStatus?

    init(selected: ProductStatus?) {
        self.selected = selected
    }

    func configureCell(cell: BasicTableViewCell, model: ProductStatus) {
        cell.selectionStyle = .default
        cell.textLabel?.text = model.description
    }

    mutating func handleSelectedChange(selected: ProductStatus) {
        self.selected = selected
    }

    func isSelected(model: ProductStatus) -> Bool {
        return model == selected
    }
}
