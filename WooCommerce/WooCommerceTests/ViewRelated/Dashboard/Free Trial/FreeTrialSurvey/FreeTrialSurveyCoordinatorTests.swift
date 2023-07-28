import XCTest
@testable import WooCommerce

final class FreeTrialSurveyCoordinatorTests: XCTestCase {
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

    func test_it_tracks_correct_event_upon_start() throws {
        // Given
        let navigationController = WooNavigationController(rootViewController: .init())
        let sut = FreeTrialSurveyCoordinator(source: .freeTrialSurvey24hAfterFreeTrialSubscribed,
                                                     navigationController: navigationController,
                                                     analytics: analytics)

        // When
        sut.start()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "free_trial_survey_displayed" }))

        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(properties["source"] as? String, "free_trial_survey_24h_after_free_trial_subscribed")
    }
}
