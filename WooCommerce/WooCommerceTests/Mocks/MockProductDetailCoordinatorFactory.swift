@testable import WooCommerce
import Yosemite

class MockProductDetailCoordinatorFactory: ProductDetailCoordinatorFactoryProtocol {
    private(set) var createdWebCoordiantor = false
    private(set) var createdNativeCoordiantor = false

    func webCoordinator(site: Site?) -> ProductDetailWebCoordinator {
        createdWebCoordiantor = true
        return MockProductDetailWebCoordinator(site: Site.fake())
    }

    func nativeCoordinator() -> ProductDetailNativeCoordinator {
        createdNativeCoordiantor = true
        return MockProductDetailNativeCoordinator()
    }
}
