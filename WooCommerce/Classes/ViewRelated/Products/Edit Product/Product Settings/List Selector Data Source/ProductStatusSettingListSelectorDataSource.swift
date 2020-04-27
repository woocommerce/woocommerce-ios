import UIKit
import Yosemite

/// `ListSelectorCommand` for selecting a Product Status Setting.
///
final class ProductStatusSettingListSelectorDataSource: ListSelectorCommand {
    typealias Model = ProductStatus
    typealias Cell = BasicTableViewCell

    let navigationBarTitle: String? = NSLocalizedString("Status", comment: "Product status setting list selector navigation title")

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

    func handleSelectedChange(selected: ProductStatus, viewController: ViewController) {
        self.selected = selected
    }

    func isSelected(model: ProductStatus) -> Bool {
        return model == selected
    }
}
