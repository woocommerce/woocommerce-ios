import UIKit
import Yosemite

/// `ListSelectorCommand` for selecting a Product Stock Status.
///
final class ProductStockStatusListSelectorDataSource: ListSelectorCommand {
    typealias Model = ProductStockStatus
    typealias Cell = BasicTableViewCell

    let navigationBarTitle: String? = NSLocalizedString("Stock status", comment: "Product stock status list selector navigation title")

    let data: [ProductStockStatus] = [
        .inStock,
        .outOfStock,
        .onBackOrder
    ]

    var selected: ProductStockStatus?

    init(selected: ProductStockStatus?) {
        self.selected = selected
    }

    func configureCell(cell: BasicTableViewCell, model: ProductStockStatus) {
        cell.selectionStyle = .default
        cell.textLabel?.text = model.description
    }

    func handleSelectedChange(selected: ProductStockStatus, viewController: ViewController) {
        self.selected = selected
    }

    func isSelected(model: ProductStockStatus) -> Bool {
        return model == selected
    }
}
