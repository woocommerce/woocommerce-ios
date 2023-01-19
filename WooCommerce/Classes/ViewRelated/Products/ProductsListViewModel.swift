import Foundation
import Yosemite

/// View model for `ProductsViewController`. Only stores logic related to Bulk Editing.
///
class ProductListViewModel {

    enum BulkEditError: Error {
        case noProductsSelected
    }

    let siteID: Int64
    private let stores: StoresManager

    private var selectedProducts: Set<Product> = .init()

    init(siteID: Int64, stores: StoresManager) {
        self.siteID = siteID
        self.stores = stores
    }

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

    /// Check if selected products share the same common ProductStatus. Returns `nil` otherwise.
    ///
    var commonStatusForSelectedProducts: ProductStatus? {
        let status = selectedProducts.first?.productStatus
        if selectedProducts.allSatisfy({ $0.productStatus == status }) {
            return status
        } else {
            return nil
        }
    }

    /// Update selected products with new ProductStatus and trigger Network action to save the change remotely.
    ///
    func updateSelectedProducts(with newStatus: ProductStatus, completion: @escaping (Result<Void, Error>) -> Void ) {
        guard selectedProductsCount > 0 else {
            completion(.failure(BulkEditError.noProductsSelected))
            return
        }

        let updatedProducts = selectedProducts.map({ $0.copy(statusKey: newStatus.rawValue) })
        let batchAction = ProductAction.updateProducts(siteID: siteID, products: updatedProducts) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        stores.dispatch(batchAction)
    }
}
