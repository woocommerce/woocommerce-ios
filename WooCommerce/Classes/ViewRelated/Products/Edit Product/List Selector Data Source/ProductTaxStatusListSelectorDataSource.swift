import UIKit
import Yosemite

/// `ListSelectorCommand` for selecting a Product Tax Status.
///
final class ProductTaxStatusListSelectorDataSource: ListSelectorCommand {
    typealias Model = ProductTaxStatus
    typealias Cell = BasicTableViewCell

    let navigationBarTitle: String? = NSLocalizedString("Tax Status", comment: "Navigation bar title of the Product tax status selector screen")

    let data: [ProductTaxStatus] = [
        .taxable,
        .shipping,
        .none
    ]

    var selected: ProductTaxStatus?

    init(selected: ProductTaxStatus?) {
        self.selected = selected
    }

    func configureCell(cell: BasicTableViewCell, model: ProductTaxStatus) {
        cell.selectionStyle = .default
        cell.textLabel?.text = model.description
    }

    func handleSelectedChange(selected: ProductTaxStatus, viewController: ViewController) {
        self.selected = selected
    }

    func isSelected(model: ProductTaxStatus) -> Bool {
        return selected == model
    }
}
