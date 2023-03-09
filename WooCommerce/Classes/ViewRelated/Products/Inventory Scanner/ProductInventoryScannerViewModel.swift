import Foundation
import Yosemite

final class ProductInventoryScannerViewModel {
    @Published private(set) var results: [ProductSKUScannerResult]

    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64, results: [ProductSKUScannerResult] = [], stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.results = results
        self.stores = stores
    }

    @MainActor
    func searchProductBySKU(barcode: String) async throws {
        // Searches in the previously scanned products first.
        for result in results {
            guard case let .matched(existingProduct, initialQuantity) = result, existingProduct.sku == barcode else {
                continue
            }
            let product = productWithIncrementedStockQuantity(for: existingProduct)
            updateResults(result: .matched(product: product, initialStockQuantity: initialQuantity))
            return
        }

        // If there is no match in the previously scanned products, searches remotely.
        return try await withCheckedThrowingContinuation { continuation in
            // TODO: 2407 - support product variations
            stores.dispatch(ProductAction.findProductBySKU(siteID: siteID, sku: barcode) { [weak self] result in
                guard let self else {
                    continuation.resume(throwing: ProductInventoryScannerError.selfDeallocated)
                    return
                }
                switch result {
                case .success(let product):
                    let productModel = self.productWithIncrementedStockQuantity(for: EditableProductModel(product: product))
                    self.updateResults(result: .matched(product: productModel, initialStockQuantity: product.stockQuantity ?? 0))
                    continuation.resume(returning: ())
                case .failure(let error):
                    self.updateResults(result: .noMatch(sku: barcode))
                    continuation.resume(throwing: error)
                }
            })
        }
    }

    @MainActor
    func updateInventory(for product: ProductFormDataModel, inventory: ProductInventoryEditableData, initialQuantity: Decimal) {
        let updatedProduct = productWithUpdatedInventory(product: product, inventory: inventory)
        updateResults(result: .matched(product: updatedProduct, initialStockQuantity: initialQuantity))
    }

    @MainActor
    func saveResults() async throws {
        let products: [ProductFormDataModel] = results.compactMap { result in
            guard case let .matched(product, _) = result else {
                return nil
            }
            return product
        }
        try await saveProducts(products)
    }
}

private extension ProductInventoryScannerViewModel {
    @MainActor
    func productWithIncrementedStockQuantity(for product: ProductFormDataModel) -> ProductFormDataModel {
        // Increments the stock quantity.
        let newStockQuantity = (product.stockQuantity ?? 0) + 1
        let inventory = ProductInventoryEditableData(sku: product.sku,
                                                     manageStock: product.manageStock,
                                                     soldIndividually: product.soldIndividually,
                                                     stockQuantity: newStockQuantity,
                                                     backordersSetting: product.backordersSetting,
                                                     stockStatus: product.stockStatus)
        return productWithUpdatedInventory(product: product, inventory: inventory)
    }

    @MainActor
    func updateResults(result: ProductSKUScannerResult) {
        if let existingResultIndex = results.firstIndex(of: result) {
            results.remove(at: existingResultIndex)
        }
        results.insert(result, at: 0)
    }

    func productWithUpdatedInventory(product: ProductFormDataModel, inventory: ProductInventoryEditableData) -> ProductFormDataModel {
        #warning("TODO: 2407 - support product variations")
        guard let productDataModel = product as? EditableProductModel else {
            return product
        }
        let productWithUpdatedInventory = productDataModel.product.copy(sku: inventory.sku,
                                                                        manageStock: inventory.manageStock,
                                                                        stockQuantity: inventory.stockQuantity,
                                                                        stockStatusKey: inventory.stockStatus?.rawValue,
                                                                        backordersKey: inventory.backordersSetting?.rawValue,
                                                                        soldIndividually: inventory.soldIndividually)
        return EditableProductModel(product: productWithUpdatedInventory)
    }

    @MainActor
    func updateInventoryRemotely(for product: ProductFormDataModel, inventory: ProductInventoryEditableData) async -> Result<Product, Error> {
        await withCheckedContinuation { continuation in
            // TODO: 2407 - support product variations
            guard let productDataModel = product as? EditableProductModel else {
                return continuation.resume(returning: .failure(ProductInventoryScannerError.inventoryUpdateFailed))
            }
            let productWithUpdatedInventory = productDataModel.product.copy(sku: inventory.sku,
                                                                            manageStock: inventory.manageStock,
                                                                            stockQuantity: inventory.stockQuantity,
                                                                            stockStatusKey: inventory.stockStatus?.rawValue,
                                                                            backordersKey: inventory.backordersSetting?.rawValue,
                                                                            soldIndividually: inventory.soldIndividually)
            stores.dispatch(ProductAction.updateProduct(product: productWithUpdatedInventory) { result in
                continuation.resume(returning: result.mapError { $0 })
            })
        }
    }

    @MainActor
    func saveProducts(_ products: [ProductFormDataModel]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let products = products.compactMap { $0 as? EditableProductModel }.map { $0.product }

            // TODO: 2407 - support product variations
            stores.dispatch(ProductAction.updateProducts(siteID: siteID, products: products) { result in
                continuation.resume(with: result.map { _ in () })
            })
        }
    }
}

enum ProductInventoryScannerError: Error, Equatable {
    case inventoryUpdateFailed
    case selfDeallocated
}
