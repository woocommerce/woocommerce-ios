import XCTest
@testable import WooCommerce

final class ProductCreationAISurveyConfirmationViewModelTests: XCTestCase {
    func test_it_tracks_startSurvey_event_when_start_survey_button_tapped() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = ProductCreationAISurveyConfirmationViewModel(onStart: {},
                                                               onSkip: {},
                                                               analytics: analytics)

        // When
        sut.didTapStartTheSurvey()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "product_creation_ai_survey_start_survey_button_tapped" }))
    }

    func test_it_tracks_skip_event_when_skip_button_tapped() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = ProductCreationAISurveyConfirmationViewModel(onStart: {},
                                                               onSkip: {},
                                                               analytics: analytics)

        // When
        sut.didTapSkip()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "product_creation_ai_survey_skip_button_tapped" }))
    }
}
