import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `ProductImagePickerView`
@MainActor
final class ProductImagePickerViewModel: ObservableObject {
    private let siteID: Int64
    private let productID: Int64
    private let stores: StoresManager
    private let storage: StorageManagerType

    @Published private(set) var loadingData = false
    @Published private(set) var productImages: [ProductImage] = []

    init(siteID: Int64,
         productID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.productID = productID
        self.stores = stores
        self.storage = storage
    }

    @MainActor
    func retrieveProductImages() async {
        // Load product from storage if it's available
        updateProductImagesFromStorage()

        // Re-sync product to get updated images
        loadingData = true
        await synchronizeProduct()
        loadingData = false

        // update product images again from storage in case any changes were found
        updateProductImagesFromStorage()
    }
}

private extension ProductImagePickerViewModel {
    func updateProductImagesFromStorage() {
        if let product = storage.viewStorage.loadProduct(siteID: siteID, productID: productID) {
            productImages = product.toReadOnly().images
        }
    }
    
    @MainActor
    func synchronizeProduct() async {
        await withCheckedContinuation { continuation in
            stores.dispatch(ProductAction.retrieveProduct(siteID: siteID, productID: productID) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    DDLogError("⛔️ Error retrieving product details to get product images: \(error)")
                    continuation.resume()
                }
            })
        }
    }
}
