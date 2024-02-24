import XCTest
@testable import WooCommerce

final class BlazeCreateCampaignIntroViewModelTests: XCTestCase {
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    func test_onAppear_tracks_introDisplayed() throws {
        // Given
        let viewModel = BlazeCreateCampaignIntroViewModel(analytics: analytics)

        // When
        viewModel.onAppear()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_intro_displayed"))
    }

    func test_onLearnHowBlazeWorks_tracks_introLearnMoreTapped() throws {
        // Given
        let viewModel = BlazeCreateCampaignIntroViewModel(analytics: analytics)

        // When
        viewModel.didTapLearnHowBlazeWorks()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_intro_learn_more_tapped"))
    }
}
