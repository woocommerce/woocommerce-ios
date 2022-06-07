import struct Yosemite.ProductImage

/// Used for `ServiceLocator.productImageUploader` if `backgroundProductImageUpload` feature flag is off.
final class LegacyProductImageUploader: ProductImageUploaderProtocol {
    func actionHandler(siteID: Int64, productID: Int64, isLocalID: Bool, originalStatuses: [ProductImageStatus]) -> ProductImageActionHandler {
        ProductImageActionHandler(siteID: siteID, productID: productID, imageStatuses: originalStatuses)
    }

    func saveProductImagesWhenNoneIsPendingUploadAnymore(siteID: Int64, productID: Int64, isLocalID: Bool, onProductSave: @escaping (Result<[ProductImage], Error>) -> Void) {
        // no-op
    }

    func hasUnsavedChangesOnImages(siteID: Int64, productID: Int64, isLocalID: Bool, originalImages: [ProductImage]) -> Bool {
        // no-op
        return false
    }
}
