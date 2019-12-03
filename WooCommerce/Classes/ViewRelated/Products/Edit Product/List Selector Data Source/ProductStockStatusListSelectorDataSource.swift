import UIKit
import Yosemite

/// `ListSelectorDataSource` for selecting a Product Stock Status.
///
struct ProductStockStatusListSelectorDataSource: ListSelectorDataSource {
    typealias Model = ProductStockStatus
    typealias Cell = BasicTableViewCell

    let data: [ProductStockStatus] = [
        .inStock,
        .outOfStock,
        .onBackOrder
    ]

    var selected: ProductStockStatus?

    init(product: Product) {
        selected = product.productStockStatus
    }

    func configureCell(cell: BasicTableViewCell, model: ProductStockStatus) {
        cell.selectionStyle = .default
        cell.textLabel?.text = model.description
    }

    mutating func handleSelectedChange(selected: ProductStockStatus) {
        self.selected = selected
    }
}
