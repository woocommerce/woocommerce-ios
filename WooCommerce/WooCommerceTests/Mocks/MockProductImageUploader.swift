import Combine
@testable import Yosemite
@testable import WooCommerce

final class MockProductImageUploader: ProductImageUploaderProtocol {
    let errors: AnyPublisher<ProductImageUploadErrorInfo, Never>

    var replaceLocalIDWasCalled = false
    var saveProductImagesWhenNoneIsPendingUploadAnymoreWasCalled = false
    var startEmittingErrorsWasCalled = false
    var stopEmittingErrorsWasCalled = false

    init(errors: AnyPublisher<ProductImageUploadErrorInfo, Never> =
         Empty<ProductImageUploadErrorInfo, Never>().eraseToAnyPublisher()) {
        self.errors = errors
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
        startEmittingErrorsWasCalled = true
    }

    func stopEmittingErrors(siteID: Int64, productID: Int64, isLocalID: Bool) {
        stopEmittingErrorsWasCalled = true
    }

    func hasUnsavedChangesOnImages(siteID: Int64, productID: Int64, isLocalID: Bool, originalImages: [ProductImage]) -> Bool {
        false
    }
}
