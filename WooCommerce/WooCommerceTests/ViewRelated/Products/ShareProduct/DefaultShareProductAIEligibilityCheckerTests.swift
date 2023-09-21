import XCTest
@testable import WooCommerce

final class DefaultShareProductAIEligibilityCheckerTests: XCTestCase {
    func test_canGenerateShareProductMessageUsingAI_is_enabled_when_site_is_wpcom() {
        // Given
        let featureFlagService = MockFeatureFlagService(isShareProductAIEnabled: true)
        let checker = DefaultShareProductAIEligibilityChecker(site: .fake().copy(isWordPressComStore: true), featureFlagService: featureFlagService)

        // Then
        XCTAssertTrue(checker.canGenerateShareProductMessageUsingAI)
    }

    func test_canGenerateShareProductMessageUsingAI_is_disabled_when_site_is_not_wpcom() {
        // Given
        let featureFlagService = MockFeatureFlagService(isShareProductAIEnabled: true)
        let checker = DefaultShareProductAIEligibilityChecker(site: .fake().copy(isWordPressComStore: false), featureFlagService: featureFlagService)

        // Then
        XCTAssertFalse(checker.canGenerateShareProductMessageUsingAI)
    }

    func test_canGenerateShareProductMessageUsingAI_is_enabled_when_site_is_not_wpcom_and_ai_assistant_feature_is_active() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isShareProductAIEnabled: true)
        let checker = DefaultShareProductAIEligibilityChecker(site: .fake().copy(isAIAssistantFeatureActive: true, isWordPressComStore: false),
                                                              featureFlagService: featureFlagService)

        // Then
        XCTAssertTrue(checker.canGenerateShareProductMessageUsingAI)
    }

    func test_canGenerateShareProductMessageUsingAI_is_disabled_when_site_is_nil() {
        // Given
        let featureFlagService = MockFeatureFlagService(isShareProductAIEnabled: true)
        let checker = DefaultShareProductAIEligibilityChecker(site: nil, featureFlagService: featureFlagService)

        // Then
        XCTAssertFalse(checker.canGenerateShareProductMessageUsingAI)
    }

    func test_canGenerateShareProductMessageUsingAI_is_disabled_when_site_is_wpcom_and_feature_flag_is_off() {
        // Given
        let featureFlagService = MockFeatureFlagService(isShareProductAIEnabled: false)
        let checker = DefaultShareProductAIEligibilityChecker(site: .fake().copy(isWordPressComStore: true), featureFlagService: featureFlagService)

        // Then
        XCTAssertFalse(checker.canGenerateShareProductMessageUsingAI)
    }
}
