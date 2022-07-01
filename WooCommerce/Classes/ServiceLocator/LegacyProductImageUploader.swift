import Combine
import struct Yosemite.ProductImage

/// Used for `ServiceLocator.productImageUploader` if `backgroundProductImageUpload` feature flag is off.
final class LegacyProductImageUploader: ProductImageUploaderProtocol {
    let errors: AnyPublisher<ProductImageUploadErrorInfo, Never> = Empty<ProductImageUploadErrorInfo, Never>().eraseToAnyPublisher()

    func actionHandler(key: ProductImageUploaderKey, originalStatuses: [ProductImageStatus]) -> ProductImageActionHandler {
        ProductImageActionHandler(siteID: key.siteID, productID: key.productOrVariationID, imageStatuses: originalStatuses)
    }

    func replaceLocalID(siteID: Int64, localID: ProductOrVariationID, remoteID: Int64) {
        // no-op
    }

    func saveProductImagesWhenNoneIsPendingUploadAnymore(key: ProductImageUploaderKey,
                                                         onProductSave: @escaping (Result<[ProductImage], Error>) -> Void) {
        // no-op
    }

    func startEmittingErrors(key: ProductImageUploaderKey) {
        // no-op
    }

    func stopEmittingErrors(key: ProductImageUploaderKey) {
        // no-op
    }

    func hasUnsavedChangesOnImages(key: ProductImageUploaderKey, originalImages: [ProductImage]) -> Bool {
        // The result is not used.
        return false
    }

    func reset() {
        // no-op
    }
}
