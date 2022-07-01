import Combine
@testable import Yosemite
@testable import WooCommerce

final class MockProductImageUploader: ProductImageUploaderProtocol {
    let errors: AnyPublisher<ProductImageUploadErrorInfo, Never>

    var replaceLocalIDWasCalled = false
    var saveProductImagesWhenNoneIsPendingUploadAnymoreWasCalled = false
    var startEmittingErrorsWasCalled = false
    var stopEmittingErrorsWasCalled = false
    var resetWasCalled = false

    init(errors: AnyPublisher<ProductImageUploadErrorInfo, Never> =
         Empty<ProductImageUploadErrorInfo, Never>().eraseToAnyPublisher()) {
        self.errors = errors
    }

    func replaceLocalID(siteID: Int64, localID: ProductOrVariationID, remoteID: Int64) {
        replaceLocalIDWasCalled = true
    }

    func saveProductImagesWhenNoneIsPendingUploadAnymore(key: ProductImageUploaderKey,
                                                         onProductSave: @escaping (Result<[ProductImage], Error>) -> Void) {
        saveProductImagesWhenNoneIsPendingUploadAnymoreWasCalled = true
    }

    func actionHandler(key: ProductImageUploaderKey, originalStatuses: [ProductImageStatus]) -> ProductImageActionHandler {
        ProductImageActionHandler(siteID: 0, productID: .product(id: 0), imageStatuses: [])
    }

    func startEmittingErrors(key: ProductImageUploaderKey) {
        startEmittingErrorsWasCalled = true
    }

    func stopEmittingErrors(key: ProductImageUploaderKey) {
        stopEmittingErrorsWasCalled = true
    }

    func hasUnsavedChangesOnImages(key: ProductImageUploaderKey, originalImages: [ProductImage]) -> Bool {
        false
    }

    func reset() {
        resetWasCalled = true
    }
}
