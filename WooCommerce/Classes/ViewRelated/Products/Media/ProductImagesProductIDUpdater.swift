import Yosemite

protocol ProductImagesProductIDUpdaterProtocol {
    /// Updates the `parent_id` of the media (productImage) using the provided `productID`.
    ///
    func updateProductIDOfImages(siteID: Int64,
                                 productID: Int64,
                                 productImage: ProductImage) async ->  Result<Media, Error>
}

struct ProductImagesProductIDUpdater {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }
}

extension ProductImagesProductIDUpdater: ProductImagesProductIDUpdaterProtocol {
    func updateProductIDOfImages(siteID: Int64,
                                 productID: Int64,
                                 productImage: ProductImage) async ->  Result<Media, Error> {
        let result = await updateProductIDFor(productImageID: productImage.imageID,
                                              siteID: siteID,
                                              productID: productID)
        if case let .failure(error) = result {
            DDLogError("⛔️ Error updating `parent_id` of media with \(productImage.imageID): \(error)")
        }
        return result
    }
}

private extension ProductImagesProductIDUpdater {
    @MainActor // Using `@MainActor` as `Dispatcher` expects the `dispatch` method to be called in main thread.
    func updateProductIDFor(productImageID: Int64,
                            siteID: Int64,
                            productID: Int64) async -> Result<Media, Error> {
        await withCheckedContinuation { continuation in
            let action = MediaAction.updateProductID(siteID: siteID, productID: productID, mediaID: productImageID) { result in
                continuation.resume(returning: result)
            }
            stores.dispatch(action)
        }
    }
}
