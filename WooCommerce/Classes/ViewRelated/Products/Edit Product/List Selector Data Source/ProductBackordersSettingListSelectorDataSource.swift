import UIKit
import Yosemite

/// `ListSelectorDataSource` for selecting a Product Backorders Setting.
///
struct ProductBackordersSettingListSelectorDataSource: ListSelectorDataSource {
    typealias Model = ProductBackordersSetting
    typealias Cell = BasicTableViewCell

    let data: [ProductBackordersSetting] = [
        .notAllowed,
        .allowedAndNotifyCustomer,
        .allowed
    ]

    var selected: ProductBackordersSetting?

    init(selected: ProductBackordersSetting?) {
        self.selected = selected
    }

    func configureCell(cell: BasicTableViewCell, model: ProductBackordersSetting) {
        cell.selectionStyle = .default
        cell.textLabel?.text = model.description
    }

    mutating func handleSelectedChange(selected: ProductBackordersSetting) {
        self.selected = selected
    }

    func isSelected(model: ProductBackordersSetting) -> Bool {
        return model == selected
    }
}
