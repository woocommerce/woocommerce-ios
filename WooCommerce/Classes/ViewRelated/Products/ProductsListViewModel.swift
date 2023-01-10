import Foundation
import Yosemite

/// View model for `ProductsViewController`. Only stores logic related to Bulk Editing.
///
class ProductListViewModel {
    private var selectedProducts: Set<Product> = .init()

    var selectedProductsCount: Int {
        selectedProducts.count
    }

    func productIsSelected(_ productToCheck: Product) -> Bool {
        return selectedProducts.contains(productToCheck)
    }

    func selectProduct(_ selectedProduct: Product) {
        selectedProducts.insert(selectedProduct)
    }

    func deselectProduct(_ selectedProduct: Product) {
        selectedProducts.remove(selectedProduct)
    }

    func deselectAll() {
        selectedProducts.removeAll()
    }
}
