@testable import Yosemite
@testable import WooCommerce

final class MockProductImagesProductIDUpdater: ProductImagesProductIDUpdaterProtocol {
    var numberOfTimesUpdateImageProductIDWasCalled = 0

    func updateImageProductID(siteID: Int64,
                              productID: Int64,
                              productImage: ProductImage) async throws -> Media {
        numberOfTimesUpdateImageProductIDWasCalled += 1
        return Media.fake()
    }
}
