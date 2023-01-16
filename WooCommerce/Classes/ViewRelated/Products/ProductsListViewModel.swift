import Foundation
import Yosemite

/// View model for `ProductsViewController`. Only stores logic related to Bulk Editing.
///
class ProductListViewModel {
    private var selectedProducts: Set<Product> = .init()

    var selectedProductsCount: Int {
        selectedProducts.count
    }

    var bulkEditActionIsEnabled: Bool {
        !selectedProducts.isEmpty
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

    var commonStatusForSelectedProducts: ProductStatus? {
        let status = selectedProducts.first?.productStatus
        if selectedProducts.allSatisfy({ $0.productStatus == status }) {
            return status
        } else {
            return nil
        }
    }
}
