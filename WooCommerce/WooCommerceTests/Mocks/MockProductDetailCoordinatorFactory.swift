@testable import WooCommerce
import Yosemite

class MockProductDetailCoordinatorFactory: ProductDetailCoordinatorFactoryProtocol {
    private(set) var createdWebCoordiantor = false
    private(set) var createdNativeCoordiantor = false
    private(set) var nativeCoordinators: [MockProductDetailNativeCoordinator] = []

    func webCoordinator(site: Site?) -> ProductDetailWebCoordinator {
        createdWebCoordiantor = true
        return MockProductDetailWebCoordinator(site: Site.fake())
    }

    func nativeCoordinator() -> ProductDetailNativeCoordinator {
        createdNativeCoordiantor = true
        let coordinator = MockProductDetailNativeCoordinator()
        nativeCoordinators.append(coordinator)
        return coordinator
    }
}
