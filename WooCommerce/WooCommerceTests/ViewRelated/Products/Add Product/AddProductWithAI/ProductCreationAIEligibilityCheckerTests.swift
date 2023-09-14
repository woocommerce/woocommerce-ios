import TestKit
import XCTest
import enum Yosemite.ProductAction

@testable import WooCommerce

@MainActor
final class ProductCreationAIEligibilityCheckerTests: XCTestCase {
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    func test_isEligible_is_true_for_wpcom_store() async throws {
        // Given
        updateDefaultStore(isWPCOMStore: true)
        updateHasProducts(hasProducts: false)
        let checker = ProductCreationAIEligibilityChecker(stores: stores)

        // When
        let isEligible = try await checker.isEligible()

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligible_is_false_for_non_wpcom_store() async throws {
        // Given
        updateDefaultStore(isWPCOMStore: false)
        updateHasProducts(hasProducts: false)
        let checker = ProductCreationAIEligibilityChecker(stores: stores)

        // When
        let isEligible = try await checker.isEligible()

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligible_is_false_for_wpcom_store_when_store_already_has_products() async throws {
        // Given
        updateDefaultStore(isWPCOMStore: true)
        updateHasProducts(hasProducts: true)
        let checker = ProductCreationAIEligibilityChecker(stores: stores)

        // When
        let isEligible = try await checker.isEligible()

        // Then
        XCTAssertFalse(isEligible)
    }
}

private extension ProductCreationAIEligibilityCheckerTests {
    func updateDefaultStore(isWPCOMStore: Bool) {
        stores.updateDefaultStore(storeID: 134)
        stores.updateDefaultStore(.fake().copy(siteID: 134, isWordPressComStore: isWPCOMStore))
    }

    func updateHasProducts(hasProducts: Bool) {
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .checkIfStoreHasProducts(_, _, completion):
                completion(.success(hasProducts))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
    }
}
