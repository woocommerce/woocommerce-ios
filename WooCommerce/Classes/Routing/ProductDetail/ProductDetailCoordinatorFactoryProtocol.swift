import Yosemite

/// Factory for producing coordinators used by the navigator.
protocol ProductDetailCoordinatorFactoryProtocol {
    func webCoordinator() -> ProductDetailCoordinator
    func nativeCoordinator() -> ProductDetailCoordinator
}

/// Default coordinator factory that wires production dependencies.
class ProductDetailCoordinatorFactory: ProductDetailCoordinatorFactoryProtocol {
    static let `default` = ProductDetailCoordinatorFactory()

    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func webCoordinator() -> ProductDetailCoordinator {
        return ProductDetailWebCoordinator(site: stores.sessionManager.defaultSite!)
    }

    func nativeCoordinator() -> ProductDetailCoordinator {
        return ProductDetailNativeCoordinator()
    }
}
