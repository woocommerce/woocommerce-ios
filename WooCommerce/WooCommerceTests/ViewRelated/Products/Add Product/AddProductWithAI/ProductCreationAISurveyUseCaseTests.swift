import XCTest
@testable import WooCommerce

final class ProductCreationAISurveyUseCaseTests: XCTestCase {
    func test_shouldShowProductCreationAISurvey_is_false_when_number_of_AI_generation_is_less_than_3() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // When
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)
        sut.didCreateAIProduct()
        sut.didCreateAIProduct()

        // Then
        XCTAssertFalse(sut.shouldShowProductCreationAISurvey())
    }

    func test_it_asks_to_show_survey_when_number_of_AI_generation_is_greater_than_3() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // When
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)
        sut.didCreateAIProduct()
        sut.didCreateAIProduct()
        sut.didCreateAIProduct()
        sut.didCreateAIProduct()

        // Then
        XCTAssertTrue(sut.shouldShowProductCreationAISurvey())
    }

    func test_it_asks_to_not_show_survey_when_number_of_AI_generation_is_greater_than_3_but_we_asked_confirmation_already() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // When
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)
        defaults.set(true, forKey: UserDefaults.Key.didSuggestProductCreationAISurvey.rawValue)
        sut.didCreateAIProduct()
        sut.didCreateAIProduct()
        sut.didCreateAIProduct()
        sut.didCreateAIProduct()

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

    func test_it_saves_asked_confirmation_value_to_defaults() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)

        // When
        sut.didSuggestProductCreationAISurvey()

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults.bool(forKey: UserDefaults.Key.didSuggestProductCreationAISurvey.rawValue)), true)
    }
}
