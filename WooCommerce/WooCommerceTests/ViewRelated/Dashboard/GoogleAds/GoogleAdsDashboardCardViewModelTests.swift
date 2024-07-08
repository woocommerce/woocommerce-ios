import XCTest
import Yosemite
@testable import WooCommerce

final class GoogleAdsDashboardCardViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 135

    @MainActor
    func test_canShowOnDashboard_returns_false_when_site_is_ineligible_for_google_ads() async {
        // Given
        let eligibilityChecker = MockGoogleAdsEligibilityChecker(isEligible: false)
        let viewModel = GoogleAdsDashboardCardViewModel(siteID: sampleSiteID, eligibilityChecker: eligibilityChecker)

        // When
        await viewModel.checkAvailability()

        // Then
        XCTAssertFalse(viewModel.canShowOnDashboard)
    }

    @MainActor
    func test_canShowOnDashboard_returns_true_when_site_is_eligible_for_google_ads() async {
        // Given
        let eligibilityChecker = MockGoogleAdsEligibilityChecker(isEligible: true)
        let viewModel = GoogleAdsDashboardCardViewModel(siteID: sampleSiteID, eligibilityChecker: eligibilityChecker)

        // When
        await viewModel.checkAvailability()

        // Then
        XCTAssertTrue(viewModel.canShowOnDashboard)
    }

}
