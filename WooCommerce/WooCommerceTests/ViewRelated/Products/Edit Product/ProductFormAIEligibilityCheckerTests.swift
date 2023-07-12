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

    func test_description_feature_is_enabled_when_site_is_jetpack_connected() {
        // Given
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIEnabled: true)
        let checker = ProductFormAIEligibilityChecker(site: .fake().copy(isJetpackThePluginInstalled: true,
                                                                         isJetpackConnected: true,
                                                                         isWordPressComStore: false), featureFlagService: featureFlagService)

        // When
        let isDescriptionAIEnabled = checker.isFeatureEnabled(.description)

        // Then
        XCTAssertTrue(isDescriptionAIEnabled)
    }

    func test_description_feature_is_enabled_when_site_is_jcp() {
        // Given
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIEnabled: true)
        let checker = ProductFormAIEligibilityChecker(site: .fake().copy(isJetpackThePluginInstalled: false,
                                                                         isJetpackConnected: true,
                                                                         isWordPressComStore: false), featureFlagService: featureFlagService)

        // When
        let isDescriptionAIEnabled = checker.isFeatureEnabled(.description)

        // Then
        XCTAssertTrue(isDescriptionAIEnabled)
    }

    func test_description_feature_is_disabled_when_logged_in_using_wporg_credentials() {
        // Given
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIEnabled: true)
        let checker = ProductFormAIEligibilityChecker(site: .fake().copy(siteID: WooConstants.placeholderStoreID),
                                                              featureFlagService: featureFlagService)
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
