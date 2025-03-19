import TestKit
import XCTest

@testable import WooCommerce

final class ProductCreationAIEligibilityCheckerTests: XCTestCase {
    private var stores: MockStoresManager!
    private var featureFlagService: MockFeatureFlagService!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting())
        featureFlagService = MockFeatureFlagService(allowMerchantAIAPIKey: false)
    }

    override func tearDown() {
        stores = nil
        featureFlagService = nil
        super.tearDown()
    }

    func test_isEligible_is_true_for_wpcom_store() throws {
        // Given
        updateDefaultStore(isWPCOMStore: true)
        let checker = ProductCreationAIEligibilityChecker(stores: stores,
                                                          featureFlagService: featureFlagService)

        // When
        let isEligible = checker.isEligible

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligible_is_false_for_non_wpcom_store() throws {
        // Given
        updateDefaultStore(isWPCOMStore: false)
        let checker = ProductCreationAIEligibilityChecker(stores: stores,
                                                          featureFlagService: featureFlagService)
        // When
        let isEligible = checker.isEligible

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligible_is_true_for_non_wpcom_store_when_ai_assistant_feature_is_active() throws {
        // Given
        updateDefaultStore(isWPCOMStore: false, isAIAssistantActive: true)
        let checker = ProductCreationAIEligibilityChecker(stores: stores,
                                                          featureFlagService: featureFlagService)
        // When
        let isEligible = checker.isEligible

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_allow_merchant_ai_api_key_as_fallback_when_flag_is_true_then_isEligible() {
        // Given
        updateDefaultStore(isWPCOMStore: false, isAIAssistantActive: false)
        let enabledFlag = MockFeatureFlagService(allowMerchantAIAPIKey: true)
        let checker = ProductCreationAIEligibilityChecker(stores: stores,
                                                          featureFlagService: enabledFlag)

        // When
        let isEligible = checker.isEligible

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_allow_merchant_ai_api_key_as_fallback_when_flag_is_false_then_is_not_eligible() {
        // Given
        updateDefaultStore(isWPCOMStore: false, isAIAssistantActive: false)
        let disabledFlag = MockFeatureFlagService(allowMerchantAIAPIKey: false)
        let checker = ProductCreationAIEligibilityChecker(stores: stores,
                                                          featureFlagService: disabledFlag)

        // When
        let isEligible = checker.isEligible

        // Then
        XCTAssertFalse(isEligible)
    }
}

private extension ProductCreationAIEligibilityCheckerTests {
    func updateDefaultStore(isWPCOMStore: Bool,
                            isAIAssistantActive: Bool = false) {
        stores.updateDefaultStore(storeID: 134)
        stores.updateDefaultStore(.fake().copy(siteID: 134,
                                               isAIAssistantFeatureActive: isAIAssistantActive,
                                               isWordPressComStore: isWPCOMStore))
    }
}
