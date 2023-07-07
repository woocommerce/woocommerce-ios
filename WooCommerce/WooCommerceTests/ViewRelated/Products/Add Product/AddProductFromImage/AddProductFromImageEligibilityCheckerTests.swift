import TestKit
import XCTest

@testable import WooCommerce

final class AddProductFromImageEligibilityCheckerTests: XCTestCase {
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    // MARK: - `isEligibleToParticipateInABTest`

    func test_isEligibleToParticipateInABTest_is_true_for_wpcom_store() throws {
        // Given
        updateDefaultStore(isWPCOMStore: true)
        let checker = AddProductFromImageEligibilityChecker(stores: stores)

        // When
        let isEligibleToParticipateInABTest = checker.isEligibleToParticipateInABTest()

        // Then
        XCTAssertTrue(isEligibleToParticipateInABTest)
    }

    func test_isEligibleToParticipateInABTest_is_false_for_non_wpcom_store() throws {
        // Given
        updateDefaultStore(isWPCOMStore: false)
        let checker = AddProductFromImageEligibilityChecker(stores: stores)

        // When
        let isEligibleToParticipateInABTest = checker.isEligibleToParticipateInABTest()

        // Then
        XCTAssertFalse(isEligibleToParticipateInABTest)
    }

    // MARK: - `isEligible`

    func test_isEligible_is_true_for_wpcom_store() throws {
        // Given
        updateDefaultStore(isWPCOMStore: true)
        let featureFlagService = MockFeatureFlagService(isAddProductFromImageEnabled: true)
        let checker = AddProductFromImageEligibilityChecker(stores: stores, featureFlagService: featureFlagService)

        // When
        let isEligible = checker.isEligible()

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligible_is_false_for_non_wpcom_store() throws {
        // Given
        updateDefaultStore(isWPCOMStore: false)
        let featureFlagService = MockFeatureFlagService(isAddProductFromImageEnabled: true)
        let checker = AddProductFromImageEligibilityChecker(stores: stores, featureFlagService: featureFlagService)

        // When
        let isEligible = checker.isEligible()

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligible_is_false_for_wpcom_store_when_feature_flag_is_disabled() throws {
        // Given
        updateDefaultStore(isWPCOMStore: true)
        let featureFlagService = MockFeatureFlagService(isAddProductFromImageEnabled: false)
        let checker = AddProductFromImageEligibilityChecker(stores: stores, featureFlagService: featureFlagService)

        // When
        let isEligible = checker.isEligible()

        // Then
        XCTAssertFalse(isEligible)
    }
}

private extension AddProductFromImageEligibilityCheckerTests {
    func updateDefaultStore(isWPCOMStore: Bool) {
        stores.updateDefaultStore(storeID: 134)
        stores.updateDefaultStore(.fake().copy(siteID: 134, isWordPressComStore: isWPCOMStore))
    }
}
