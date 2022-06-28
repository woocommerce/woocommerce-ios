import Combine
@testable import Yosemite
@testable import WooCommerce

final class MockProductImageUploader: ProductImageUploaderProtocol {
    let errors: AnyPublisher<ProductImageUploadErrorInfo, Never>

    var replaceLocalIDWasCalled = false
    var saveProductImagesWhenNoneIsPendingUploadAnymoreWasCalled = false
    var startEmittingStatusUpdatesWasCalled = false
    var stopEmittingStatusUpdatesWasCalled = false

    init(statusUpdates: AnyPublisher<ProductImageUploadErrorInfo, Never> =
         Empty<ProductImageUploadErrorInfo, Never>().eraseToAnyPublisher()) {
        self.errors = statusUpdates
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

    func startEmittingErrors(siteID: Int64, productID: Int64, isLocalID: Bool) {
        startEmittingStatusUpdatesWasCalled = true
    }

    func stopEmittingErrors(siteID: Int64, productID: Int64, isLocalID: Bool) {
        stopEmittingStatusUpdatesWasCalled = true
    }

    func hasUnsavedChangesOnImages(siteID: Int64, productID: Int64, isLocalID: Bool, originalImages: [ProductImage]) -> Bool {
        false
    }
}
