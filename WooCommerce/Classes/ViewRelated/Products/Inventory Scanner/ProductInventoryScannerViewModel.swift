import Foundation
import Yosemite

final class ProductInventoryScannerViewModel {
    @Published private(set) var results: [ProductSKUScannerResult] = []

    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    @MainActor
    func searchProductBySKU(barcode: String) async -> Result<Product, Error> {
        await withCheckedContinuation { continuation in
            // TODO: 2407 - support product variations
            stores.dispatch(ProductAction.findProductBySKU(siteID: siteID, sku: barcode) { result in
                continuation.resume(returning: result)
            })
        }
    }

    @MainActor
    func updateInventory(for product: ProductFormDataModel, inventory: ProductInventoryEditableData) async -> Result<Product, Error> {
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

enum ProductInventoryScannerError: Error {
    case inventoryUpdateFailed
}
