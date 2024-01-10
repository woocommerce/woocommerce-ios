import XCTest
@testable import WooCommerce

final class ProductCreationAISurveyUseCaseTests: XCTestCase {
    func test_shouldShowProductCreationAISurvey_is_true_if_survey_not_displayed_before() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // When
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)

        // Then
        XCTAssertTrue(sut.shouldShowProductCreationAISurvey())
    }

    func test_it_asks_to_show_survey_if_user_dismissed_first_time() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // When
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)
        XCTAssertTrue(sut.shouldShowProductCreationAISurvey())

        sut.didSuggestProductCreationAISurvey()

        // Then
        XCTAssertTrue(sut.shouldShowProductCreationAISurvey())
    }

    func test_it_asks_to_not_show_survey_if_user_dismissed_second_time() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // When
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)
        XCTAssertTrue(sut.shouldShowProductCreationAISurvey())

        sut.didSuggestProductCreationAISurvey()
        sut.didSuggestProductCreationAISurvey()

        // Then
        XCTAssertFalse(sut.shouldShowProductCreationAISurvey())
    }

    func test_it_asks_to_not_show_survey_if_user_started_survey_already() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)
        defaults.set(true, forKey: UserDefaults.Key.didStartProductCreationAISurvey.rawValue)

        // When
        sut.didStartProductCreationAISurvey()

        // Then
        XCTAssertFalse(sut.shouldShowProductCreationAISurvey())
    }

    func test_it_tracks_confirmationViewDisplayed_event_when_we_ask_for_confirmation() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = ProductCreationAISurveyUseCase(defaults: defaults,
                                                 analytics: analytics)

        // When
        sut.didSuggestProductCreationAISurvey()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "product_creation_ai_survey_confirmation_view_displayed" }))
    }

    // MARK: haveSuggestedSurveyBefore

    func test_haveSuggestedSurveyBefore_is_false_if_survey_not_displayed_before() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // When
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)

        // Then
        XCTAssertFalse(sut.haveSuggestedSurveyBefore())
    }

    func test_haveSuggestedSurveyBefore_is_true_if_survey_displayed_before() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)

        // When
        sut.didSuggestProductCreationAISurvey()

        // Then
        XCTAssertTrue(sut.haveSuggestedSurveyBefore())
    }
}
