import Testing
import UIKit
import Yosemite

@testable import WooCommerce

@MainActor
extension ProductFormViewController_DuplicationTests {
    @Test
    func test_product_loader_duplication_replaces_contained_source_editor() async throws {
        // Given
        let sourceProduct = Product.fake().copy(productID: 123, name: "Source")
        let duplicate = sourceProduct.copy(productID: 456, name: "Source Copy")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        configureDuplication(stores: stores, sourceProduct: sourceProduct, duplicate: duplicate)
        let context = NavigationTestContext(stores: stores)
        defer { context.cleanUp() }
        let loader = ProductLoaderViewController(model: .product(productID: sourceProduct.productID),
                                                 siteID: sourceProduct.siteID,
                                                 forceReadOnly: false)
        context.present(UINavigationController(rootViewController: loader))
        loader.loadViewIfNeeded()
        let source = try await productFormChild(in: loader)

        // When
        source.handleProductDuplication()
        try await waitUntil {
            loader.children.contains { $0 is ProductFormViewController<ProductFormViewModel> && $0 !== source }
        }

        // Then
        let destination = try await productFormChild(in: loader)
        #expect(destination !== source)
        #expect(loader.children.count == 1)
        #expect(source.parent == nil)
        #expect(destination.parent === loader)
    }

    @Test
    func test_add_product_form_after_first_save_replaces_source_editor() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let context = NavigationTestContext(stores: stores)
        defer { context.cleanUp() }
        let previous = UIViewController()
        let navigationController = UINavigationController(rootViewController: previous)
        context.present(navigationController)
        let coordinator = AddProductCoordinator(siteID: 123,
                                                source: .productDescriptionAIAnnouncementModal,
                                                sourceView: nil,
                                                sourceNavigationController: navigationController,
                                                isFirstProduct: false)
        coordinator.start()
        let source = try #require(navigationController.topViewController as? ProductFormViewController<ProductFormViewModel>)
        let viewModel = try #require(productViewModel(in: source))
        let savedProduct = viewModel.productModel.product.copy(productID: 123, statusKey: ProductStatus.draft.rawValue)
        let duplicate = savedProduct.copy(productID: 456, name: "Source Copy")
        configureDuplication(stores: stores, sourceProduct: savedProduct, duplicate: duplicate)
        viewModel.updateProductVariations(from: savedProduct)

        // When
        source.handleProductDuplication()
        try await waitUntil { navigationController.topViewController !== source }

        // Then
        #expect(navigationController.viewControllers.count == 2)
        #expect(navigationController.viewControllers[0] === previous)
        #expect(navigationController.viewControllers[1] !== source)
        #expect(source.navigationController == nil)
    }
}

@MainActor
private extension ProductFormViewController_DuplicationTests {
    func configureDuplication(stores: MockStoresManager, sourceProduct: Product, duplicate: Product) {
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .duplicateProduct(_, productID, onCompletion) where productID == sourceProduct.productID:
                onCompletion(.success(duplicate.productID))
            case let .retrieveProduct(_, productID, onCompletion) where productID == sourceProduct.productID:
                onCompletion(.success(sourceProduct))
            case let .retrieveProduct(_, productID, onCompletion) where productID == duplicate.productID:
                onCompletion(.success(duplicate))
            default:
                break
            }
        }
    }

    func productFormChild(in loader: ProductLoaderViewController) async throws -> ProductFormViewController<ProductFormViewModel> {
        try await waitUntil {
            loader.children.contains { $0 is ProductFormViewController<ProductFormViewModel> }
        }
        return try #require(loader.children.compactMap { $0 as? ProductFormViewController<ProductFormViewModel> }.first)
    }

    func productViewModel(in productForm: ProductFormViewController<ProductFormViewModel>) -> ProductFormViewModel? {
        Mirror(reflecting: productForm).children.first { $0.label == "viewModel" }?.value as? ProductFormViewModel
    }

    func waitUntil(_ condition: @escaping @MainActor () -> Bool) async throws {
        for _ in 0..<100 {
            if condition() {
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        #expect(condition())
    }
}

@MainActor
private final class NavigationTestContext {
    private let originalStores: StoresManager
    private let window = UIWindow(frame: UIScreen.main.bounds)

    init(stores: StoresManager) {
        originalStores = ServiceLocator.stores
        ServiceLocator.setStores(stores)
        window.makeKeyAndVisible()
    }

    func present(_ viewController: UIViewController) {
        window.rootViewController = viewController
        viewController.loadViewIfNeeded()
    }

    func cleanUp() {
        window.resignKey()
        window.rootViewController = nil
        ServiceLocator.setStores(originalStores)
    }
}
