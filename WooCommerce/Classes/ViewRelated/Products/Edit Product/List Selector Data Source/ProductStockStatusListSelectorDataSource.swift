import UIKit
import Yosemite

struct ProductStockStatusListSelectorDataSource: ListSelectorDataSource {
    typealias Model = ProductStockStatus

    let data: [ProductStockStatus] = [
        .inStock,
        .outOfStock,
        .onBackOrder
    ]

    var selected: ProductStockStatus? {
        return product.productStockStatus
    }

    let onSelectedChange: (ProductStockStatus) -> Void

    private let product: Product

    init(product: Product, onSelectedChange: @escaping (ProductStockStatus) -> Void) {
        self.product = product
        self.onSelectedChange = onSelectedChange
    }

    func configureCell(cell: BasicTableViewCell, model: ProductStockStatus) {
        cell.selectionStyle = .default
        cell.textLabel?.text = model.rawValue
    }
}
