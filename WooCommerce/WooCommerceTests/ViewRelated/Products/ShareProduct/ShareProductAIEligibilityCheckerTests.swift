import XCTest
@testable import WooCommerce

final class ShareProductAIEligibilityCheckerTests: XCTestCase {
    func test_canGenerateShareProductMessageUsingAI_is_enabled_when_site_is_wpcom() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isShareProductAIEnabled: true)
        let checker = ShareProductAIEligibilityChecker(site: .fake().copy(isWordPressComStore: true), featureFlagService: featureFlagService)

        // Then
        XCTAssertTrue(checker.canGenerateShareProductMessageUsingAI)
    }

    func test_canGenerateShareProductMessageUsingAI_is_disabled_when_site_is_not_wpcom() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isShareProductAIEnabled: true)
        let checker = ShareProductAIEligibilityChecker(site: .fake().copy(isWordPressComStore: false), featureFlagService: featureFlagService)

        // Then
        XCTAssertFalse(checker.canGenerateShareProductMessageUsingAI)
    }

    func test_canGenerateShareProductMessageUsingAI_is_disabled_when_site_is_nil() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isShareProductAIEnabled: true)
        let checker = ShareProductAIEligibilityChecker(site: nil, featureFlagService: featureFlagService)

        // Then
        XCTAssertFalse(checker.canGenerateShareProductMessageUsingAI)
    }

    func test_canGenerateShareProductMessageUsingAI_is_disabled_when_site_is_wpcom_and_feature_flag_is_off() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isShareProductAIEnabled: false)
        let checker = ShareProductAIEligibilityChecker(site: .fake().copy(isWordPressComStore: true), featureFlagService: featureFlagService)

        // Then
        XCTAssertFalse(checker.canGenerateShareProductMessageUsingAI)
    }
}
