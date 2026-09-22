import TestKit
import XCTest

@testable import WooCommerce

final class ProductCreationAIEligibilityCheckerTests: XCTestCase {
    private var stores: MockStoresManager!

    @MainActor
    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    @MainActor
    func test_isEligible_is_true_for_wpcom_store() throws {
        // Given
        updateDefaultStore(isWPCOMStore: true)
        let checker = ProductCreationAIEligibilityChecker(stores: stores)

        // When
        let isEligible = checker.isEligible

        // Then
        XCTAssertTrue(isEligible)
    }

    @MainActor
    func test_isEligible_is_false_for_non_wpcom_store() throws {
        // Given
        updateDefaultStore(isWPCOMStore: false)
        let checker = ProductCreationAIEligibilityChecker(stores: stores)
        // When
        let isEligible = checker.isEligible

        // Then
        XCTAssertFalse(isEligible)
    }

    @MainActor
    func test_isEligible_is_true_for_non_wpcom_store_when_ai_assistant_feature_is_active() throws {
        // Given
        updateDefaultStore(isWPCOMStore: false, isAIAssistantActive: true)
        let checker = ProductCreationAIEligibilityChecker(stores: stores)
        // When
        let isEligible = checker.isEligible

        // Then
        XCTAssertTrue(isEligible)
    }
}

private extension ProductCreationAIEligibilityCheckerTests {
    @MainActor
    func updateDefaultStore(isWPCOMStore: Bool,
                            isAIAssistantActive: Bool = false) {
        stores.updateDefaultStore(storeID: 134)
        stores.updateDefaultStore(.fake().copy(siteID: 134,
                                               isAIAssistantFeatureActive: isAIAssistantActive,
                                               isWordPressComStore: isWPCOMStore))
    }
}
