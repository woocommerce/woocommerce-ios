import UIKit
import Yosemite

/// `ListSelectorCommand` for filtering a list of products by product status.
final class FilterProductsByProductStatusListSelectorCommand: ListSelectorCommand {
    typealias Model = ProductStatus?
    typealias Cell = BasicTableViewCell

    let navigationBarTitle: String? = NSLocalizedString("Product status",
                                                        comment: "Navigation bar title of the selector for filtering products by product status.")

    let data: [ProductStatus?] = [nil, .publish, .draft, .pending]

    private(set) var selected: ProductStatus??

    private let onSelectedChange: (_ selected: ProductStatus?) -> Void

    init(selected: ProductStatus?, onSelectedChange: @escaping (_ selected: ProductStatus?) -> Void) {
        self.selected = selected
        self.onSelectedChange = onSelectedChange
    }

    func handleSelectedChange(selected: ProductStatus?, viewController: ViewController) {
        self.selected = selected
        onSelectedChange(selected ?? nil)
    }

    func isSelected(model: ProductStatus?) -> Bool {
        return model == selected
    }

    func configureCell(cell: BasicTableViewCell, model: ProductStatus?) {
        cell.textLabel?.text = model?.description ?? Constant.noFilterValueTitle
    }

    private enum Constant {
        static let noFilterValueTitle = NSLocalizedString("Any", comment: "Title when there is no filter set.")
    }
}
