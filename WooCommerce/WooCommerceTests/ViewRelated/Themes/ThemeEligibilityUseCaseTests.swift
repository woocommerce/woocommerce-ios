import Experiments
import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ThemeEligibilityUseCaseTests: XCTestCase {

    func test_site_not_eligible_for_lightweight_storefront_if_store_is_not_wpcom() {
        // Given
        let checker = ThemeEligibilityUseCase()
        let site = Site.fake().copy(isWordPressComStore: false)

        // When
        let isEligibleForLightweightStorefront = checker.isEligible(site: site)

        // Then
        XCTAssertFalse(isEligibleForLightweightStorefront)
    }

    func test_site_eligible_for_lightweight_storefront_if_store_is_wpcom() {
        // Given
        let checker = ThemeEligibilityUseCase()
        let site = Site.fake().copy(isWordPressComStore: true)

        // When
        let isEligibleForLightweightStorefront = checker.isEligible(site: site)

        // Then
        XCTAssertTrue(isEligibleForLightweightStorefront)
    }
}
