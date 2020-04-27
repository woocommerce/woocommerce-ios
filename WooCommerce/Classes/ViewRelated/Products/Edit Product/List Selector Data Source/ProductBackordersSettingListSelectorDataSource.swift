import UIKit
import Yosemite

/// `ListSelectorCommand` for selecting a Product Backorders Setting.
///
final class ProductBackordersSettingListSelectorDataSource: ListSelectorCommand {
    typealias Model = ProductBackordersSetting
    typealias Cell = BasicTableViewCell

    let navigationBarTitle: String? = NSLocalizedString("Backorders", comment: "Product backorders setting list selector navigation title")

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

    func handleSelectedChange(selected: ProductBackordersSetting, viewController: ViewController) {
        self.selected = selected
    }

    func isSelected(model: ProductBackordersSetting) -> Bool {
        return model == selected
    }
}
