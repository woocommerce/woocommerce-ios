import XCTest
@testable import WooCommerce
@testable import Yosemite

final class FreeTrialSurveyViewModelTests: XCTestCase {
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

    // MARK: `answers`

    func test_answers_has_correct_values() {
        // Given
        let viewModel = FreeTrialSurveyViewModel(source: .freeTrialSurvey24hAfterFreeTrialSubscribed,
                                                 onClose: {},
                                                 analytics: analytics)

        // Then
        XCTAssertEqual(viewModel.answers, FreeTrialSurveyViewModel.SurveyAnswer.allCases)
    }

    // MARK: `selectAnswer(:)`

    func test_selectAnswer_method_updates_selectedAnswer() {
        // Given
        let viewModel = FreeTrialSurveyViewModel(source: .freeTrialSurvey24hAfterFreeTrialSubscribed,
                                                 onClose: {},
                                                 analytics: analytics)
        // When
        viewModel.selectAnswer(.collectiveDecision)

        // Then
        XCTAssertEqual(viewModel.selectedAnswer, .collectiveDecision)
    }

    // MARK: `feedbackSelected`

    func test_feedbackSelected_is_false_initially() {
        // Given
        let viewModel = FreeTrialSurveyViewModel(source: .freeTrialSurvey24hAfterFreeTrialSubscribed,
                                                 onClose: {},
                                                 analytics: analytics)

        // Then
        XCTAssertFalse(viewModel.feedbackSelected)
    }

    func test_feedbackSelected_is_true_when_answer_is_selected() {
        // Given
        let viewModel = FreeTrialSurveyViewModel(source: .freeTrialSurvey24hAfterFreeTrialSubscribed,
                                                 onClose: {},
                                                 analytics: analytics)
        // When
        viewModel.selectAnswer(.collectiveDecision)

        // Then
        XCTAssertTrue(viewModel.feedbackSelected)
    }

    func test_feedbackSelected_is_false_when_otherReasons_is_selected_and_otherReasonSpecified_is_empty() {
        // Given
        let viewModel = FreeTrialSurveyViewModel(source: .freeTrialSurvey24hAfterFreeTrialSubscribed,
                                                 onClose: {},
                                                 analytics: analytics)
        // When
        viewModel.selectAnswer(.otherReasons)
        viewModel.otherReasonSpecified = ""

        // Then
        XCTAssertFalse(viewModel.feedbackSelected)
    }

    func test_feedbackSelected_is_true_when_otherReasons_is_selected_and_otherReasonSpecified_is_empty() {
        // Given
        let viewModel = FreeTrialSurveyViewModel(source: .freeTrialSurvey24hAfterFreeTrialSubscribed,
                                                 onClose: {},
                                                 analytics: analytics)
        // When
        viewModel.selectAnswer(.otherReasons)
        viewModel.otherReasonSpecified = "Need time to decide"

        // Then
        XCTAssertTrue(viewModel.feedbackSelected)
    }

    // MARK: `submitFeedback`

    func test_submitFeedback_method_tracks_correct_event_when_selected_a_given_answer() throws {
        // Given
        let viewModel = FreeTrialSurveyViewModel(source: .freeTrialSurvey24hAfterFreeTrialSubscribed,
                                                 onClose: {},
                                                 analytics: analytics)
        viewModel.selectAnswer(.comparingWithOtherPlatforms)

        // When
        viewModel.submitFeedback()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "free_trial_survey_sent" }))

        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(properties["source"] as? String, "free_trial_survey_24h_after_free_trial_subscribed")
        XCTAssertEqual(properties["survey_option"] as? String, "comparing_with_other_platforms")
    }

    func test_submitFeedback_method_tracks_correct_event_when_entered_otherReasons() throws {
        // Given
        let viewModel = FreeTrialSurveyViewModel(source: .freeTrialSurvey24hAfterFreeTrialSubscribed,
                                                 onClose: {},
                                                 analytics: analytics)
        viewModel.selectAnswer(.otherReasons)
        viewModel.otherReasonSpecified = "Need time to decide"

        // When
        viewModel.submitFeedback()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "free_trial_survey_sent" }))

        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(properties["source"] as? String, "free_trial_survey_24h_after_free_trial_subscribed")
        XCTAssertEqual(properties["survey_option"] as? String, "other_reasons")
        XCTAssertEqual(properties["free_text"] as? String, "Need time to decide")
    }

    func test_submitFeedback_method_tracks_free_text_even_when_selected_a_given_answer() throws {
        // Given
        let viewModel = FreeTrialSurveyViewModel(source: .freeTrialSurvey24hAfterFreeTrialSubscribed,
                                                 onClose: {},
                                                 analytics: analytics)
        viewModel.selectAnswer(.comparingWithOtherPlatforms)
        viewModel.otherReasonSpecified = "Need time to decide"

        // When
        viewModel.submitFeedback()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "free_trial_survey_sent" }))

        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(properties["source"] as? String, "free_trial_survey_24h_after_free_trial_subscribed")
        XCTAssertEqual(properties["survey_option"] as? String, "comparing_with_other_platforms")
        XCTAssertEqual(properties["free_text"] as? String, "Need time to decide")
    }

    func test_submitFeedback_method_does_not_track_free_text_if_it_is_empty() throws {
        // Given
        let viewModel = FreeTrialSurveyViewModel(source: .freeTrialSurvey24hAfterFreeTrialSubscribed,
                                                 onClose: {},
                                                 analytics: analytics)
        viewModel.selectAnswer(.comparingWithOtherPlatforms)
        viewModel.otherReasonSpecified = ""

        // When
        viewModel.submitFeedback()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "free_trial_survey_sent" }))
        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertNil(properties["free_text"])
    }

    func test_onClose_is_fired_when_submitting_feedback() {
        var onCloseFired = false
        let viewModel = FreeTrialSurveyViewModel(source: .freeTrialSurvey24hAfterFreeTrialSubscribed,
                                                 onClose: {
            onCloseFired = true
        },
                                                 analytics: analytics)
        viewModel.selectAnswer(.comparingWithOtherPlatforms)
        viewModel.otherReasonSpecified = "Need time to decide"

        // When
        viewModel.submitFeedback()

        // Then
        XCTAssertTrue(onCloseFired)
    }

    // MARK: Local notification after three days

    func test_threeDaysAfterStillExploring_local_notification_is_scheduled_if_submitted_answer_is_stillExploring() throws {
        // Given
        let sampleSiteID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: Site.fake().copy(siteID: sampleSiteID)))

        let pushNotesManager = MockPushNotificationsManager()
        let viewModel = FreeTrialSurveyViewModel(source: .freeTrialSurvey24hAfterFreeTrialSubscribed,
                                                 onClose: {},
                                                 stores: stores,
                                                 analytics: analytics,
                                                 pushNotesManager: pushNotesManager,
                                                 inAppPurchaseManager: MockInAppPurchasesForWPComPlansManager(isIAPSupported: true))

        // When
        viewModel.selectAnswer(.stillExploring)
        viewModel.submitFeedback()

        // Then
        waitUntil(timeout: 3) {
            pushNotesManager.requestedLocalNotificationsIfNeeded.isNotEmpty
        }
        let ids = pushNotesManager.requestedLocalNotificationsIfNeeded.map(\.scenario.identifier)
        let expectedID = LocalNotification.Scenario.Identifier.Prefix.threeDaysAfterStillExploring + "\(sampleSiteID)"
        XCTAssertTrue(ids.contains(expectedID))
    }

    func test_threeDaysAfterStillExploring_local_notification_is_not_scheduled_if_submitted_answer_is_not_stillExploring() throws {
        // Given
        let sampleSiteID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: Site.fake().copy(siteID: sampleSiteID)))

        let pushNotesManager = MockPushNotificationsManager()
        let viewModel = FreeTrialSurveyViewModel(source: .freeTrialSurvey24hAfterFreeTrialSubscribed,
                                                 onClose: {},
                                                 stores: stores,
                                                 analytics: analytics,
                                                 pushNotesManager: pushNotesManager,
                                                 inAppPurchaseManager: MockInAppPurchasesForWPComPlansManager(isIAPSupported: true))

        // When
        viewModel.selectAnswer(.collectiveDecision)
        viewModel.submitFeedback()

        // Then
        let ids = pushNotesManager.requestedLocalNotificationsIfNeeded.map(\.scenario.identifier)
        let expectedID = LocalNotification.Scenario.Identifier.Prefix.threeDaysAfterStillExploring + "\(sampleSiteID)"
        XCTAssertFalse(ids.contains(expectedID))
    }
}
