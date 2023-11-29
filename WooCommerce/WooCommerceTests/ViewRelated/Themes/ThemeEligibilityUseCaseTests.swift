import Experiments
import XCTest
@testable import WooCommerce
@testable import Yosemite

class ThemeEligibilityUseCaseTests: XCTestCase {
    func test_site_not_eligible_for_lightweight_storefront_if_feature_flag_disabled() {
        // Given
        let featureFlagService = MockFeatureFlagService(isLightweightStorefrontEnabled: false)
        let checker = ThemeEligibilityUseCase(featureFlagService: featureFlagService)
        let site = Site.fake().copy(isWordPressComStore: true)

        // When
        let isEligibleForLightweightStorefront = checker.isEligible(site: site)

        // Then

        XCTAssertFalse(isEligibleForLightweightStorefront)
    }

    func test_site_not_eligible_for_lightweight_storefront_if_feature_flag_enabled_but_is_not_wpcom_store() {
        // Given
        let featureFlagService = MockFeatureFlagService(isLightweightStorefrontEnabled: true)
        let checker = ThemeEligibilityUseCase(featureFlagService: featureFlagService)
        let site = Site.fake().copy(isWordPressComStore: false)

        // When
        let isEligibleForLightweightStorefront = checker.isEligible(site: site)

        // Then

        XCTAssertFalse(isEligibleForLightweightStorefront)
    }

    func test_site_eligible_for_lightweight_storefront_if_feature_flag_enabled_and_is_wpcom_store() {
        // Given
        let featureFlagService = MockFeatureFlagService(isLightweightStorefrontEnabled: true)
        let checker = ThemeEligibilityUseCase(featureFlagService: featureFlagService)
        let site = Site.fake().copy(isWordPressComStore: true)

        // When
        let isEligibleForLightweightStorefront = checker.isEligible(site: site)

        // Then

        XCTAssertTrue(isEligibleForLightweightStorefront)
    }
}
