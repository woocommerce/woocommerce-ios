@testable import Yosemite
@testable import WooCommerce

final class MockProductImagesProductIDUpdater: ProductImagesProductIDUpdaterProtocol {
    var numberOfTimesUpdateImageProductIDWasCalled = 0

    func updateImageProductID(siteID: Int64,
                              productID: Int64,
                              productImage: ProductImage) async ->  Result<Media, Error> {
        numberOfTimesUpdateImageProductIDWasCalled += 1
        return .success(Media.fake())
    }
}
