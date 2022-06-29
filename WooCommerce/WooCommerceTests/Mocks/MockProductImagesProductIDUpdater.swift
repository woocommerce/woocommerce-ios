@testable import Yosemite
@testable import WooCommerce

final class MockProductImagesProductIDUpdater: ProductImagesProductIDUpdaterProtocol {
    var updateImageProductIDWasCalled = false

    func updateImageProductID(siteID: Int64,
                              productID: Int64,
                              productImage: ProductImage) async throws -> Media {
        updateImageProductIDWasCalled = true
        return Media.fake()
    }
}
