import TestKit
import XCTest
import enum Yosemite.ProductAction

@testable import WooCommerce

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

    func test_isEligible_is_true_for_wpcom_store() throws {
        // Given
        updateDefaultStore(isWPCOMStore: true)
        let checker = ProductCreationAIEligibilityChecker(stores: stores,
                                                          storeHasProducts: false)

        // When
        let isEligible = checker.isEligible()

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligible_is_false_for_non_wpcom_store() throws {
        // Given
        updateDefaultStore(isWPCOMStore: false)
        let checker = ProductCreationAIEligibilityChecker(stores: stores,
                                                          storeHasProducts: false)

        // When
        let isEligible = checker.isEligible()

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligible_is_false_for_wpcom_store_when_store_already_has_products() throws {
        // Given
        updateDefaultStore(isWPCOMStore: true)
        let checker = ProductCreationAIEligibilityChecker(stores: stores,
                                                          storeHasProducts: true)

        // When
        let isEligible = checker.isEligible()

        // Then
        XCTAssertFalse(isEligible)
    }
}

private extension ProductCreationAIEligibilityCheckerTests {
    func updateDefaultStore(isWPCOMStore: Bool) {
        stores.updateDefaultStore(storeID: 134)
        stores.updateDefaultStore(.fake().copy(siteID: 134, isWordPressComStore: isWPCOMStore))
    }
}
