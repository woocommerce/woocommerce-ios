import Yosemite

protocol ProductImagesProductIDUpdaterProtocol {
    /// Updates the `parent_id` of the  `productImage`(media) using the provided `productID`.
    ///
    /// - Parameters:
    ///   - siteID: ID of the site in which the media and product is present.
    ///   - productID: ID of the product which needs to be set as `parent_id` for the `productImage`
    ///   - productImage: Image for which the `parent_id` needs to be updated
    ///
    func updateImageProductID(siteID: Int64,
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
    func updateImageProductID(siteID: Int64,
                              productID: Int64,
                              productImage: ProductImage) async -> Result<Media, Error> {
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
