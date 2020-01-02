import UIKit
import Yosemite

/// `ListSelectorDataSource` for selecting a Product Tax Status.
///
struct ProductTaxStatusListSelectorDataSource: ListSelectorDataSource {
    typealias Model = ProductTaxStatus
    typealias Cell = BasicTableViewCell

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

    mutating func handleSelectedChange(selected: ProductTaxStatus) {
        self.selected = selected
    }

    mutating func isSelected(model: ProductTaxStatus) -> Bool {
        return selected == model
    }
}
