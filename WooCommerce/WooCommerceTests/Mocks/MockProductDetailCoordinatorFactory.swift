@testable import WooCommerce

class MockProductDetailCoordinatorFactory: ProductDetailCoordinatorFactoryProtocol {
    private(set) var createdWebCoordiantor = false
    private(set) var createdNativeCoordiantor = false

    func webCoordinator() -> ProductDetailCoordinator {
        createdWebCoordiantor = true
        return MockProductDetailCoordinator()
    }

    func nativeCoordinator() -> ProductDetailCoordinator {
        createdNativeCoordiantor = true
        return MockProductDetailCoordinator()
    }
}
