@testable import WooCommerce
import Testing
import UIKit
import Yosemite

@MainActor
final class ProductDetailNavigatorTests {
    private static let aNonBookingProduct = Product.fake().copy(productTypeKey: "simple")
    private static let aNewBookingProduct = Product.fake().copy(productTypeKey: "bookable-service")
    private static let aLegacyBookingProduct = Product.fake().copy(productTypeKey: "booking")
    private lazy var coordinatorFactory = MockProductDetailCoordinatorFactory()

    // MARK: - Non-bookable products

    @Test
    func non_bookable_product_directs_to_native_view() {
        // Given
        let navigator = ProductDetailNavigator(
            coordinatorFactory: coordinatorFactory
        )

        // When
        _ = navigator.makeDestination(product: Self.aNonBookingProduct, isReadOnly: false)

        // Then
        #expect(coordinatorFactory.createdNativeCoordiantor)
        #expect(!coordinatorFactory.createdWebCoordiantor)
    }

    // MARK: - New booking type (bookable-service)

    @Test
    func new_booking_product_directs_to_native_view() {
        // Given
        let navigator = ProductDetailNavigator(
            coordinatorFactory: coordinatorFactory
        )

        // When
        _ = navigator.makeDestination(product: Self.aNewBookingProduct, isReadOnly: false)

        // Then
        #expect(coordinatorFactory.createdNativeCoordiantor)
        #expect(!coordinatorFactory.createdWebCoordiantor)
    }

    // MARK: - Legacy booking type

    @Test
    func legacy_booking_product_directs_to_web_view() {
        // Given
        let navigator = ProductDetailNavigator(
            coordinatorFactory: coordinatorFactory
        )

        // When
        _ = navigator.makeDestination(product: Self.aLegacyBookingProduct, isReadOnly: false)

        // Then
        #expect(coordinatorFactory.createdWebCoordiantor)
        #expect(!coordinatorFactory.createdNativeCoordiantor)
    }

    @Test
    func test_duplicate_navigation_without_owner_callback_replaces_source_in_navigation_stack() async throws {
        // Given
        let coordinatorFactory = MockProductDetailCoordinatorFactory()
        let navigator = ProductDetailNavigator(coordinatorFactory: coordinatorFactory)
        let source = navigator.makeDestination(product: Self.aNonBookingProduct, isReadOnly: false)
        let sourceCoordinator = try #require(coordinatorFactory.nativeCoordinators.first)
        let previous = UIViewController()
        let navigationController = UINavigationController()
        navigationController.viewControllers = [previous, source]
        let initialViewControllers = navigationController.viewControllers
        let sourceIndex = try #require(initialViewControllers.firstIndex { $0 === source })
        let previousIndex = try #require(initialViewControllers.firstIndex { $0 === previous })
        let duplicate = Self.aNonBookingProduct.copy(productID: 456)

        // When
        sourceCoordinator.onDuplicate?(source, duplicate)
        try await waitUntil { navigationController.viewControllers.contains { $0 === source } == false }

        // Then
        #expect(navigationController.viewControllers.count == initialViewControllers.count)
        #expect(navigationController.viewControllers[previousIndex] === previous)
        #expect(navigationController.viewControllers[sourceIndex] !== source)
        #expect(source.navigationController == nil)
        #expect(coordinatorFactory.nativeCoordinators.count == 2)

        // And the replacement carries the same default replacement behavior.
        let firstDuplicateDestination = navigationController.viewControllers[sourceIndex]
        let firstDuplicateCoordinator = coordinatorFactory.nativeCoordinators[1]
        firstDuplicateCoordinator.onDuplicate?(firstDuplicateDestination, duplicate.copy(productID: 789))
        try await waitUntil { navigationController.viewControllers.contains { $0 === firstDuplicateDestination } == false }
        #expect(navigationController.viewControllers.count == initialViewControllers.count)
        #expect(navigationController.viewControllers[sourceIndex] !== firstDuplicateDestination)
        #expect(firstDuplicateDestination.navigationController == nil)
        #expect(coordinatorFactory.nativeCoordinators.count == 3)
    }

    @Test
    func test_duplicate_navigation_with_owner_callback_executes_owner_once_without_default_push_or_replace() throws {
        // Given
        let coordinatorFactory = MockProductDetailCoordinatorFactory()
        let navigator = ProductDetailNavigator(coordinatorFactory: coordinatorFactory)
        var navigatedProducts: [Product] = []
        let source = navigator.makeDestination(product: Self.aNonBookingProduct,
                                               isReadOnly: false,
                                               onDuplicate: { navigatedProducts.append($0) })
        let sourceCoordinator = try #require(coordinatorFactory.nativeCoordinators.first)
        let navigationController = UINavigationController(rootViewController: source)
        let duplicate = Self.aNonBookingProduct.copy(productID: 456)

        // When
        sourceCoordinator.onDuplicate?(source, duplicate)

        // Then
        #expect(navigatedProducts == [duplicate])
        #expect(navigationController.viewControllers.count == 1)
        #expect(navigationController.viewControllers.first === source)
        #expect(coordinatorFactory.nativeCoordinators.count == 1)
    }

    private func waitUntil(_ condition: @escaping @MainActor () -> Bool) async throws {
        for _ in 0..<100 {
            if condition() {
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        #expect(condition())
    }
}
