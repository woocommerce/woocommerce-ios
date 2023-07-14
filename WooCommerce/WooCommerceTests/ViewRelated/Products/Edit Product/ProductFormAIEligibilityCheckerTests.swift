import XCTest
@testable import WooCommerce

final class ProductFormAIEligibilityCheckerTests: XCTestCase {
    // MARK: - Product description

    func test_description_feature_is_enabled_when_site_is_wpcom() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIEnabled: true)
        let checker = ProductFormAIEligibilityChecker(site: .fake().copy(isWordPressComStore: true), featureFlagService: featureFlagService)

        // When
        let isDescriptionAIEnabled = checker.isFeatureEnabled(.description)

        // Then
        XCTAssertTrue(isDescriptionAIEnabled)
    }

    func test_description_feature_is_disabled_when_site_is_not_wpcom() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIEnabled: true)
        let checker = ProductFormAIEligibilityChecker(site: .fake().copy(isWordPressComStore: false), featureFlagService: featureFlagService)

        // When
        let isDescriptionAIEnabled = checker.isFeatureEnabled(.description)

        // Then
        XCTAssertFalse(isDescriptionAIEnabled)
    }

    func test_description_feature_is_disabled_when_site_is_nil() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIEnabled: true)
        let checker = ProductFormAIEligibilityChecker(site: nil, featureFlagService: featureFlagService)

        // When
        let isDescriptionAIEnabled = checker.isFeatureEnabled(.description)

        // Then
        XCTAssertFalse(isDescriptionAIEnabled)
    }

    func test_description_feature_is_disabled_when_site_is_wpcom_and_feature_flag_is_off() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIEnabled: false)
        let checker = ProductFormAIEligibilityChecker(site: .fake().copy(isWordPressComStore: true), featureFlagService: featureFlagService)

        // When
        let isDescriptionAIEnabled = checker.isFeatureEnabled(.description)

        // Then
        XCTAssertFalse(isDescriptionAIEnabled)
    }
}
