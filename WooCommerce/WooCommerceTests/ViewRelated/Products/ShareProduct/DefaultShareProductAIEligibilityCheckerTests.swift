import XCTest
@testable import WooCommerce

final class DefaultShareProductAIEligibilityCheckerTests: XCTestCase {
    func test_canGenerateShareProductMessageUsingAI_is_enabled_when_site_is_wpcom() {
        // Given
        let checker = DefaultShareProductAIEligibilityChecker(site: .fake().copy(isWordPressComStore: true))

        // Then
        XCTAssertTrue(checker.canGenerateShareProductMessageUsingAI)
    }

    func test_canGenerateShareProductMessageUsingAI_is_disabled_when_site_is_not_wpcom() {
        // Given
        let checker = DefaultShareProductAIEligibilityChecker(site: .fake().copy(isWordPressComStore: false))

        // Then
        XCTAssertFalse(checker.canGenerateShareProductMessageUsingAI)
    }

    func test_canGenerateShareProductMessageUsingAI_is_enabled_when_site_is_not_wpcom_and_ai_assistant_feature_is_active() throws {
        // Given
        let checker = DefaultShareProductAIEligibilityChecker(site: .fake().copy(isAIAssistantFeatureActive: true, isWordPressComStore: false))

        // Then
        XCTAssertTrue(checker.canGenerateShareProductMessageUsingAI)
    }

    func test_canGenerateShareProductMessageUsingAI_is_disabled_when_site_is_nil() {
        // Given
        let checker = DefaultShareProductAIEligibilityChecker(site: nil)

        // Then
        XCTAssertFalse(checker.canGenerateShareProductMessageUsingAI)
    }
}
