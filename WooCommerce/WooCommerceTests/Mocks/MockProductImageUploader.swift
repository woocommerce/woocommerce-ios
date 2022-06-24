import Combine
@testable import Yosemite
@testable import WooCommerce

final class MockProductImageUploader: ProductImageUploaderProtocol {
    let statusUpdates: AnyPublisher<ProductImageUploadUpdate, Never>

    var replaceLocalIDWasCalled = false
    var saveProductImagesWhenNoneIsPendingUploadAnymoreWasCalled = false
    var startEmittingStatusUpdatesWasCalled = false
    var stopEmittingStatusUpdatesWasCalled = false

    init(statusUpdates: AnyPublisher<ProductImageUploadUpdate, Never> =
         Empty<ProductImageUploadUpdate, Never>().eraseToAnyPublisher()) {
        self.statusUpdates = statusUpdates
    }

    func replaceLocalID(siteID: Int64, localProductID: Int64, remoteProductID: Int64) {
        replaceLocalIDWasCalled = true
    }

    func saveProductImagesWhenNoneIsPendingUploadAnymore(siteID: Int64,
                                                         productID: Int64,
                                                         isLocalID: Bool,
                                                         onProductSave: @escaping (Result<[ProductImage], Error>) -> Void) {
        saveProductImagesWhenNoneIsPendingUploadAnymoreWasCalled = true
    }

    func actionHandler(siteID: Int64, productID: Int64, isLocalID: Bool, originalStatuses: [ProductImageStatus]) -> ProductImageActionHandler {
        ProductImageActionHandler(siteID: 0, productID: 0, imageStatuses: [])
    }

    func startEmittingStatusUpdates(siteID: Int64, productID: Int64, isLocalID: Bool) {
        startEmittingStatusUpdatesWasCalled = true
    }

    func stopEmittingStatusUpdates(siteID: Int64, productID: Int64, isLocalID: Bool) {
        stopEmittingStatusUpdatesWasCalled = true
    }

    func hasUnsavedChangesOnImages(siteID: Int64, productID: Int64, isLocalID: Bool, originalImages: [ProductImage]) -> Bool {
        false
    }
}
