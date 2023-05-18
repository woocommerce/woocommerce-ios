import XCTest
import TestKit

@testable import WooCommerce
@testable import Yosemite

final class PrivacyBannerViewModelTest: XCTestCase {

    func test_analytics_state_has_correct_initial_value_when_user_has_opt_out() {
        // Given
        let analytics = WaitingTimeTrackerTests.TestAnalytics()
        analytics.userHasOptedIn = false

        // When
        let viewModel = PrivacyBannerViewModel(analytics: analytics)

        // Then
        XCTAssertFalse(viewModel.analyticsEnabled)
    }

    func test_analytics_state_has_correct_initial_value_when_user_has_opt_in() {
        // Given
        let analytics = WaitingTimeTrackerTests.TestAnalytics()
        analytics.userHasOptedIn = true

        // When
        let viewModel = PrivacyBannerViewModel(analytics: analytics)

        // Then
        XCTAssertTrue(viewModel.analyticsEnabled)
    }
}
