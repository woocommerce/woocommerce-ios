import XCTest
import TestKit

@testable import WooCommerce
@testable import Yosemite

final class PrivacyBannerViewModelTest: XCTestCase {

    func test_analytics_state_has_correct_initial_value_when_user_has_opt_out() {
        // Given
        let analytics = WooAnalytics(analyticsProvider: MockAnalyticsProvider())
        analytics.setUserHasOptedOut(true)

        // When
        let viewModel = PrivacyBannerViewModel(analyticsProvider: analytics)

        // Then
        XCTAssertFalse(viewModel.analyticsEnabled)
    }

    func test_analytics_state_has_correct_initial_value_when_user_has_opt_int() {
        // Given
        let analytics = WooAnalytics(analyticsProvider: MockAnalyticsProvider())
        analytics.setUserHasOptedOut(false)

        // When
        let viewModel = PrivacyBannerViewModel(analyticsProvider: analytics)

        // Then
        XCTAssertTrue(viewModel.analyticsEnabled)
    }
}
