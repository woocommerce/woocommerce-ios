import Combine
import struct Yosemite.ProductImage

/// Used for `ServiceLocator.productImageUploader` if `backgroundProductImageUpload` feature flag is off.
final class LegacyProductImageUploader: ProductImageUploaderProtocol {
    let errors: AnyPublisher<ProductImageUploadErrorInfo, Never> = Empty<ProductImageUploadErrorInfo, Never>().eraseToAnyPublisher()

    func actionHandler(siteID: Int64, productID: Int64, isLocalID: Bool, originalStatuses: [ProductImageStatus]) -> ProductImageActionHandler {
        ProductImageActionHandler(siteID: siteID, productID: productID, imageStatuses: originalStatuses)
    }

    func replaceLocalID(siteID: Int64, localProductID: Int64, remoteProductID: Int64) {
        // no-op
    }

    func saveProductImagesWhenNoneIsPendingUploadAnymore(siteID: Int64,
                                                         productID: Int64,
                                                         isLocalID: Bool,
                                                         onProductSave: @escaping (Result<[ProductImage], Error>) -> Void) {
        // no-op
    }

    func startEmittingErrors(siteID: Int64, productID: Int64, isLocalID: Bool) {
        // no-op
    }

    func stopEmittingErrors(siteID: Int64, productID: Int64, isLocalID: Bool) {
        // no-op
    }

    func hasUnsavedChangesOnImages(siteID: Int64, productID: Int64, isLocalID: Bool, originalImages: [ProductImage]) -> Bool {
        // The result is not used.
        return false
    }

    func reset() {
        // no-op
    }
}
