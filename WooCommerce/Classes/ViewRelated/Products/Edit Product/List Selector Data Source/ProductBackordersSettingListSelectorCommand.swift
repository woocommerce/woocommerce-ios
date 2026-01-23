import UIKit
import Yosemite

/// `ListSelectorCommand` for selecting a Product Backorders Setting.
///
final class ProductBackordersSettingListSelectorCommand: ListSelectorCommand {
    typealias Model = ProductBackordersSetting
    typealias Cell = BasicTableViewCell

    let navigationBarTitle: String? = NSLocalizedString("Backorders", comment: "This text appears as a cell title in the Product Inventory Settings screen and as the navigation bar title when users select backorder settings for a product. It allows merchants to configure whether customers can order items that are currently out of stock.")

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
