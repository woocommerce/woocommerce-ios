import UIKit
import Yosemite

/// `ListSelectorCommand` for filtering a list of products by product type.
final class FilterProductsByProductTypeListSelectorCommand: ListSelectorCommand {
    typealias Model = ProductType?
    typealias Cell = BasicTableViewCell

    let navigationBarTitle: String? = NSLocalizedString("Product type", comment: "Navigation bar title of the selector for filtering products by product type.")

    let data: [ProductType?] = [nil, .simple, .variable, .grouped, .affiliate]

    private(set) var selected: ProductType??

    private let onSelectedChange: (_ selected: ProductType?) -> Void

    init(selected: ProductType?, onSelectedChange: @escaping (_ selected: ProductType?) -> Void) {
        self.selected = selected
        self.onSelectedChange = onSelectedChange
    }

    func handleSelectedChange(selected: ProductType?, viewController: ViewController) {
        self.selected = selected
        onSelectedChange(selected ?? nil)
    }

    func isSelected(model: ProductType?) -> Bool {
        return model == selected
    }

    func configureCell(cell: BasicTableViewCell, model: ProductType?) {
        cell.textLabel?.text = model?.description ?? Constant.noFilterValueTitle
    }

    private enum Constant {
        static let noFilterValueTitle = NSLocalizedString("Any", comment: "Title when there is no filter set.")
    }
}
