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
    func searchProductBySKU(barcode: String) async -> Result<Void, Error> {
        // Searches in the previously scanned products first.
        if let existingProduct = results.compactMap({ result -> ProductFormDataModel? in
            guard case let .matched(product) = result else {
                return nil
            }
            return product
        }).first(where: { $0.sku == barcode }) {
            let product = productWithIncrementedStockQuantity(for: existingProduct)
            updateResults(result: .matched(product: product))
            return .success(())
        }

        // If there is no match in the previously scanned products, searches remotely.
        return await withCheckedContinuation { continuation in
            // TODO: 2407 - support product variations
            stores.dispatch(ProductAction.findProductBySKU(siteID: siteID, sku: barcode) { [weak self] result in
                guard let self else {
                    return continuation.resume(returning: .failure(ProductInventoryScannerError.selfDeallocated))
                }
                switch result {
                case .success(let product):
                    let productModel = self.productWithIncrementedStockQuantity(for: EditableProductModel(product: product))
                    self.updateResults(result: .matched(product: productModel))
                    continuation.resume(returning: .success(()))
                case .failure(let error):
                    self.updateResults(result: .noMatch(sku: barcode))
                    continuation.resume(returning: .failure(error))
                }
            })
        }
    }

    @MainActor
    func updateInventory(for product: ProductFormDataModel, inventory: ProductInventoryEditableData) {
        let updatedProduct = productWithUpdatedInventory(product: product, inventory: inventory)
        updateResults(result: .matched(product: updatedProduct))
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
            let existingResult = results[existingResultIndex]
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
}

enum ProductInventoryScannerError: Error, Equatable {
    case inventoryUpdateFailed
    case selfDeallocated
}
