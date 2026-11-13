import Foundation
import Testing
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
struct UnsupportedBundledProductCheckerTests {
    private let siteID: Int64 = 123

    @Test
    func check_when_no_child_is_restricted_then_the_bundle_is_supported() async {
        // Given
        let bundle = makeBundle(childIDs: [2, 3])
        let checker = makeChecker(children: [simpleProduct(id: 2), simpleProduct(id: 3)])

        // When
        let result = await checker.check(bundle: bundle)

        // Then
        #expect(result == .supported)
    }

    @Test
    func check_when_a_child_is_a_subscription_then_the_bundle_is_unsupported() async {
        // Given
        let bundle = makeBundle(childIDs: [2, 3])
        let subscription = product(id: 3, productType: .subscription)
        let checker = makeChecker(children: [simpleProduct(id: 2), subscription])

        // When
        let result = await checker.check(bundle: bundle)

        // Then
        #expect(result == .unsupported(.subscription))
    }

    @Test
    func check_when_a_child_is_bookable_then_the_bundle_is_unsupported() async {
        // Given
        let bundle = makeBundle(childIDs: [2])
        let checker = makeChecker(children: [product(id: 2, productType: .booking)])

        // When
        let result = await checker.check(bundle: bundle)

        // Then
        #expect(result == .unsupported(.bookable))
    }

    @Test
    func check_when_a_child_cannot_be_resolved_then_the_result_is_unknown() async {
        // Given
        // Two children are declared but only one comes back.
        let bundle = makeBundle(childIDs: [2, 3])
        let checker = makeChecker(children: [simpleProduct(id: 2)])

        // When
        let result = await checker.check(bundle: bundle)

        // Then
        #expect(result == .unknown)
    }

    @Test
    func check_when_a_child_is_restricted_and_another_is_unresolved_then_the_restriction_wins() async {
        // Given
        let bundle = makeBundle(childIDs: [2, 3, 4])
        let checker = makeChecker(children: [product(id: 2, productType: .subscription)])

        // When
        let result = await checker.check(bundle: bundle)

        // Then
        #expect(result == .unsupported(.subscription))
    }

    @Test
    func check_when_loading_the_children_fails_then_the_result_is_unknown() async {
        // Given
        let bundle = makeBundle(childIDs: [2])
        let checker = makeChecker(error: NSError(domain: "Test", code: 0))

        // When
        let result = await checker.check(bundle: bundle)

        // Then
        #expect(result == .unknown)
    }

    @Test
    func check_when_the_bundle_has_no_bundled_items_then_it_is_supported() async {
        // Given
        // Nothing to resolve, so no request is made and there is nothing which could be unsupported.
        let bundle = makeBundle(childIDs: [])
        let checker = makeChecker(error: NSError(domain: "Test", code: 0))

        // When
        let result = await checker.check(bundle: bundle)

        // Then
        #expect(result == .supported)
    }
}

private extension UnsupportedBundledProductCheckerTests {
    func makeBundle(childIDs: [Int64]) -> Product {
        Product.fake().copy(siteID: siteID,
                            productID: 1,
                            productTypeKey: ProductType.bundle.rawValue,
                            bundledItems: childIDs.map { .fake().copy(bundledItemID: $0, productID: $0) })
    }

    func product(id: Int64, productType: ProductType) -> Product {
        Product.fake().copy(siteID: siteID, productID: id, productTypeKey: productType.rawValue, purchasable: true)
    }

    func simpleProduct(id: Int64) -> Product {
        product(id: id, productType: .simple)
    }

    /// Builds a checker whose child lookup returns `children`, or fails with `error`.
    func makeChecker(children: [Product] = [], error: Error? = nil) -> UnsupportedBundledProductChecker {
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .retrieveProductsIfNeeded(_, _, onCompletion) = action else {
                return
            }

            if let error {
                return onCompletion(.failure(error))
            }

            onCompletion(.success(children))
        }

        return UnsupportedBundledProductChecker(stores: stores)
    }
}
