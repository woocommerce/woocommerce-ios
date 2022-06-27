@testable import Yosemite
@testable import WooCommerce

final class MockProductImageUploader: ProductImageUploaderProtocol {
    var replaceLocalIDWasCalled = false
    var saveProductImagesWhenNoneIsPendingUploadAnymoreWasCalled = false

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

    func hasUnsavedChangesOnImages(siteID: Int64, productID: Int64, isLocalID: Bool, originalImages: [ProductImage]) -> Bool {
        false
    }
}
