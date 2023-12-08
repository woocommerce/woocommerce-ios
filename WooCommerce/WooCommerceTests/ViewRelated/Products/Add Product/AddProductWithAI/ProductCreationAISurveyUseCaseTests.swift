import XCTest
@testable import WooCommerce

final class ProductCreationAISurveyUseCaseTests: XCTestCase {
    func test_it_saves_numberOfTimesAIProductCreated_to_defaults() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)

        // When
        sut.numberOfTimesAIProductCreated = 5

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults.integer(forKey: UserDefaults.Key.numberOfTimesAIProductCreated.rawValue)), 5)
    }

    func test_numberOfTimesAIProductCreated_is_restored_from_user_defaults() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults.set(3, forKey: UserDefaults.Key.numberOfTimesAIProductCreated.rawValue)

        // When
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)

        // Then
        XCTAssertEqual(sut.numberOfTimesAIProductCreated, 3)
    }

    func test_shouldShowProductCreationAISurvey_is_false_when_number_of_AI_generation_is_less_than_3() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // When
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)
        sut.numberOfTimesAIProductCreated = Int.random(in: 0..<3)

        // Then
        XCTAssertFalse(sut.shouldShowProductCreationAISurvey())
    }

    func test_it_asks_to_show_survey_when_number_of_AI_generation_is_greater_than_3() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // When
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)
        sut.numberOfTimesAIProductCreated = 4

        // Then
        XCTAssertTrue(sut.shouldShowProductCreationAISurvey())
    }

    func test_it_asks_to_not_show_survey_when_number_of_AI_generation_is_greater_than_3_but_we_asked_confirmation_already() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // When
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)
        defaults.set(true, forKey: UserDefaults.Key.haveAskedConfirmationToShowProductCreationAISurvey.rawValue)
        sut.numberOfTimesAIProductCreated = 4

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
        sut.didAskConfirmationToShowProductCreationAISurvey()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "product_creation_ai_survey_confirmation_view_displayed" }))
    }

    func test_it_saves_asked_confirmation_value_to_defaults() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = ProductCreationAISurveyUseCase(defaults: defaults)

        // When
        sut.didAskConfirmationToShowProductCreationAISurvey()

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults.bool(forKey: UserDefaults.Key.haveAskedConfirmationToShowProductCreationAISurvey.rawValue)), true)
    }
}
