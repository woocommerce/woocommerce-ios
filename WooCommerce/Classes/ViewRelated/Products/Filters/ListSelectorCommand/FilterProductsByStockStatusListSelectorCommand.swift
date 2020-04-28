import UIKit
import Yosemite

/// `ListSelectorCommand` for filtering a list of products by stock status.
final class FilterProductsByStockStatusListSelectorCommand: ListSelectorCommand {
    typealias Model = ProductStockStatus?
    typealias Cell = BasicTableViewCell

    let navigationBarTitle: String? = NSLocalizedString("Stock status", comment: "Navigation bar title of the selector for filtering products by stock status.")

    let data: [ProductStockStatus?] = [nil, .inStock, .outOfStock, .onBackOrder]

    private(set) var selected: ProductStockStatus??

    private let onSelectedChange: (_ selected: ProductStockStatus?) -> Void

    init(selected: ProductStockStatus?, onSelectedChange: @escaping (_ selected: ProductStockStatus?) -> Void) {
        self.selected = selected
        self.onSelectedChange = onSelectedChange
    }

    func handleSelectedChange(selected: ProductStockStatus?, viewController: ViewController) {
        self.selected = selected
        onSelectedChange(selected ?? nil)
    }

    func isSelected(model: ProductStockStatus?) -> Bool {
        return model == selected
    }

    func configureCell(cell: BasicTableViewCell, model: ProductStockStatus?) {
        cell.textLabel?.text = model?.description ?? Constant.noFilterValueTitle
    }

    private enum Constant {
        static let noFilterValueTitle = NSLocalizedString("Any", comment: "Title when there is no filter set.")
    }
}
