import XCTest
@testable import WooCommerce

final class ProductFormAIEligibilityCheckerTests: XCTestCase {
    // MARK: - Product description

    func test_description_feature_is_enabled_when_site_is_wpcom() throws {
        // Given
        let checker = ProductFormAIEligibilityChecker(site: .fake().copy(isWordPressComStore: true))

        // When
        let isDescriptionAIEnabled = checker.isFeatureEnabled(.description)

        // Then
        XCTAssertTrue(isDescriptionAIEnabled)
    }

    func test_description_feature_is_disabled_when_site_is_not_wpcom() throws {
        // Given
        let checker = ProductFormAIEligibilityChecker(site: .fake().copy(isWordPressComStore: false))

        // When
        let isDescriptionAIEnabled = checker.isFeatureEnabled(.description)

        // Then
        XCTAssertFalse(isDescriptionAIEnabled)
    }

    func test_description_feature_is_enabled_when_site_is_not_wpcom_and_ai_assistant_feature_is_active() throws {
        // Given
        let checker = ProductFormAIEligibilityChecker(site: .fake().copy(isAIAssistantFeatureActive: true, isWordPressComStore: false))

        // When
        let isDescriptionAIEnabled = checker.isFeatureEnabled(.description)

        // Then
        XCTAssertTrue(isDescriptionAIEnabled)
    }

    func test_description_feature_is_disabled_when_site_is_nil() throws {
        // Given
        let checker = ProductFormAIEligibilityChecker(site: nil)

        // When
        let isDescriptionAIEnabled = checker.isFeatureEnabled(.description)

        // Then
        XCTAssertFalse(isDescriptionAIEnabled)
    }
}
