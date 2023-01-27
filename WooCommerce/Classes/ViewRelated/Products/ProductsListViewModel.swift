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

    private(set) var selectedProducts: Set<Product> = .init()

    init(siteID: Int64, stores: StoresManager) {
        self.siteID = siteID
        self.stores = stores
    }

    var selectedProductsCount: Int {
        selectedProducts.count
    }

    var selectedVariableProductsCount: Int {
        selectedProducts.filter({ $0.productType == .variable }).count
    }

    /// Product types that are incompatible with bulk update of regular price
    ///
    private let priceIncompatibleProductsTypes: Set<ProductType> = [
        .variable,
        .grouped,
        .custom("booking")
    ]

    /// Number of selected products that are incompatible with bulk update of regular price
    ///
    var selectedPriceIncompatibleProductsCount: Int {
        selectedProducts.filter({ priceIncompatibleProductsTypes.contains($0.productType) }).count
    }

    /// Boolean indicating if all of selected products are incompatible with bulk update of regular price
    ///
    var onlyPriceIncompatibleProductsSelected: Bool {
        !selectedProducts.isEmpty && onlyPriceCompatibleSelectedProducts.isEmpty
    }

    /// Subset of selected products filtered for types that support bulk update of regular price
    ///
    private var onlyPriceCompatibleSelectedProducts: Set<Product> {
        selectedProducts.filter({ !priceIncompatibleProductsTypes.contains($0.productType) })
    }

    var bulkEditActionIsEnabled: Bool {
        !selectedProducts.isEmpty
    }

    func productIsSelected(_ productToCheck: Product) -> Bool {
        return selectedProducts.contains(productToCheck)
    }

    func selectProduct(_ product: Product) {
        selectedProducts.insert(product)
    }

    func selectProducts(_ products: [Product]) {
        selectedProducts.formUnion(products)
    }

    func deselectProduct(_ product: Product) {
        selectedProducts.remove(product)
    }

    func deselectAll() {
        selectedProducts.removeAll()
    }

    /// Represents if a property in a collection of `Product`  has the same value or different values or is missing.
    ///
    enum BulkValue: Equatable {
        /// All variations have the same value
        case value(String)
        /// When variations have mixed values.
        case mixed
        /// None of the variation has a value
        case none
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

    /// Check if selected products share the same common ProductStatus. Returns `nil` otherwise.
    ///
    var commonPriceForSelectedProducts: BulkValue {
        if selectedProducts.allSatisfy({ $0.regularPrice?.isEmpty != false }) {
            return .none
        } else if let price = selectedProducts.first?.regularPrice, selectedProducts.allSatisfy({ $0.regularPrice == price }) {
            return .value(price)
        } else {
            return .mixed
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

    /// Update selected products with new price and trigger Network action to save the change remotely.
    ///
    func updateSelectedProducts(with newPrice: String, completion: @escaping (Result<Void, Error>) -> Void ) {
        guard !onlyPriceIncompatibleProductsSelected else {
            completion(.failure(BulkEditError.noProductsSelected))
            return
        }

        let updatedProducts = onlyPriceCompatibleSelectedProducts.map({ $0.copy(regularPrice: newPrice) })
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
