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
                              productImage: ProductImage) async throws -> Media
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
                              productImage: ProductImage) async throws -> Media {
        try await updateProductIDFor(productImageID: productImage.imageID,
                                     siteID: siteID,
                                     productID: productID)
    }
}

private extension ProductImagesProductIDUpdater {
    @MainActor // Using `@MainActor` as `Dispatcher` expects the `dispatch` method to be called in main thread.
    func updateProductIDFor(productImageID: Int64,
                            siteID: Int64,
                            productID: Int64) async throws -> Media {
        try await withCheckedThrowingContinuation { continuation in
            let action = MediaAction.updateProductID(siteID: siteID, productID: productID, mediaID: productImageID) { result in
                switch result {
                case .failure(let error):
                    DDLogError("⛔️ Error updating `parent_id` of media with \(productImageID): \(error)")
                    continuation.resume(throwing: error)
                case .success(let media):
                    continuation.resume(returning: media)
                }
            }
            stores.dispatch(action)
        }
    }
}
