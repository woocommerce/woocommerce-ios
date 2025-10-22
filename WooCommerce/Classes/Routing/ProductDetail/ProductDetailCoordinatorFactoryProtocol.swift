import Yosemite

/// Factory for producing coordinators used by the navigator.
protocol ProductDetailCoordinatorFactoryProtocol {
    func webCoordinator(site: Site?) -> ProductDetailWebCoordinator
    func nativeCoordinator() -> ProductDetailNativeCoordinator
}

/// Default coordinator factory that wires production dependencies.
class ProductDetailCoordinatorFactory: ProductDetailCoordinatorFactoryProtocol {
    static let `default` = ProductDetailCoordinatorFactory()

    func webCoordinator(site: Site?) -> ProductDetailWebCoordinator {
        return ProductDetailWebCoordinator(site: site)
    }

    func nativeCoordinator() -> ProductDetailNativeCoordinator {
        return ProductDetailNativeCoordinator()
    }
}
