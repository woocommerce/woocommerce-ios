import XCTest
@testable import WooCommerce
@testable import Yosemite

final class StoreCreationProfilerQuestionContainerViewModelTests: XCTestCase {

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analyticsProvider = nil
        analytics = nil
        super.tearDown()
    }

    // MARK: - Saving answers

    func test_saveSellingStatus_updates_currentQuestion_to_category() {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { _ in })
        XCTAssertEqual(viewModel.currentQuestion, .sellingStatus)

        // When
        viewModel.saveSellingStatus(nil)

        // Then
        XCTAssertEqual(viewModel.currentQuestion, .category)
    }

    func test_saveCategory_updates_currentQuestion_to_country() {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { _ in })

        // When
        viewModel.saveCategory(nil)

        // Then
        XCTAssertEqual(viewModel.currentQuestion, .country)
    }

    func test_saveCountry_updates_currentQuestion_to_challenges() {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { _ in })

        // When
        viewModel.saveCountry(.US)

        // Then
        XCTAssertEqual(viewModel.currentQuestion, .challenges)
    }

    func test_saveFeatures_triggers_onCompletion() throws {
        // Given
        var profilerData: StoreProfilerAnswers?
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { profilerData = $0 })

        // When
        viewModel.saveSellingStatus(.init(sellingStatus: .justStarting, sellingPlatforms: nil))
        viewModel.saveCategory(nil)
        viewModel.saveCountry(.US)
        viewModel.saveChallenges([])
        viewModel.saveFeatures([])

        // Then
        let data = try XCTUnwrap(profilerData)
        XCTAssertEqual(data.sellingStatus, .justStarting)
        XCTAssertNil(data.sellingPlatforms)
        XCTAssertEqual(data.countryCode, "US")
    }

    // MARK: - `backtrackOrDismissProfiler`

    func test_backtrackOrDismissProfiler_triggers_completionHandler_without_profiler_data_if_current_question_is_selling_status() {
        // Given
        var triggeredCompletion = false
        var profilerData: StoreProfilerAnswers?
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: {
            profilerData = $0
            triggeredCompletion = true
        })
        XCTAssertEqual(viewModel.currentQuestion, .sellingStatus)

        // When
        viewModel.backtrackOrDismissProfiler()

        // Then
        XCTAssertTrue(triggeredCompletion)
        XCTAssertNil(profilerData)
    }

    func test_backtrackOrDismissProfiler_sets_current_question_to_selling_status_if_current_question_is_category() {
        // Given
        var triggeredCompletion = false
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { _ in triggeredCompletion = true })
        viewModel.saveSellingStatus(nil)

        // When
        viewModel.backtrackOrDismissProfiler()

        // Then
        XCTAssertFalse(triggeredCompletion)
        XCTAssertEqual(viewModel.currentQuestion, .sellingStatus)
    }

    func test_backtrackOrDismissProfiler_sets_current_question_to_category_if_current_question_is_country() {
        // Given
        var triggeredCompletion = false
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { _ in triggeredCompletion = true })
        viewModel.saveCategory(nil)

        // When
        viewModel.backtrackOrDismissProfiler()

        // Then
        XCTAssertFalse(triggeredCompletion)
        XCTAssertEqual(viewModel.currentQuestion, .category)
    }

    func test_backtrackOrDismissProfiler_sets_current_question_to_country_if_current_question_is_challenges() {
        // Given
        var triggeredCompletion = false
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { _ in triggeredCompletion = true })
        viewModel.saveCountry(.US)

        // When
        viewModel.backtrackOrDismissProfiler()

        // Then
        XCTAssertFalse(triggeredCompletion)
        XCTAssertEqual(viewModel.currentQuestion, .country)
    }

    func test_backtrackOrDismissProfiler_sets_current_question_to_challenges_if_current_question_is_features() {
        // Given
        var triggeredCompletion = false
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { _ in triggeredCompletion = true })
        viewModel.saveChallenges([])

        // When
        viewModel.backtrackOrDismissProfiler()

        // Then
        XCTAssertFalse(triggeredCompletion)
        XCTAssertEqual(viewModel.currentQuestion, .challenges)
    }

    // MARK: - Analytics

    func test_onAppear_tracks_site_creation_event_for_selling_status_question() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", analytics: analytics, onCompletion: { _ in })

        // When
        viewModel.onAppear()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_step" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_commerce_journey")
    }

    func test_saveSellingStatus_tracks_skip_event_for_selling_status_question() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", analytics: analytics, onCompletion: { _ in })

        // When
        viewModel.saveSellingStatus(nil)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_profiler_question_skipped" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_commerce_journey")
    }

    func test_saveSellingStatus_tracks_skip_event_for_selling_platform_question() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", analytics: analytics, onCompletion: { _ in })

        // When
        viewModel.saveSellingStatus(.init(sellingStatus: .alreadySellingOnline, sellingPlatforms: nil))

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_profiler_question_skipped" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_ecommerce_platforms")
    }

    func test_saveSellingStatus_tracks_site_creation_event_for_category_question() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", analytics: analytics, onCompletion: { _ in })

        // When
        viewModel.saveSellingStatus(.init(sellingStatus: .alreadySellingOnline, sellingPlatforms: nil))

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_step" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_industries")
    }

    func test_saveCategory_tracks_skip_event_for_category_question() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", analytics: analytics, onCompletion: { _ in })

        // When
        viewModel.saveCategory(nil)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_profiler_question_skipped" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_industries")
    }

    func test_saveCategory_tracks_site_creation_event_for_country_question() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", analytics: analytics, onCompletion: { _ in })

        // When
        viewModel.saveCategory(nil)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_step" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_country")
    }


    func test_saveCountry_tracks_site_creation_event_for_country_features() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", analytics: analytics, onCompletion: { _ in })

        // When
        viewModel.saveCountry(.AD)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_step" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_challenges")
    }

    func test_saveChallenges_tracks_skip_event_for_challenges_questions() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", analytics: analytics, onCompletion: { _ in })

        // When
        viewModel.saveChallenges([])

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_profiler_question_skipped" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_challenges")
    }

    func test_saveChallenges_tracks_site_creation_event_for_features_question() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", analytics: analytics, onCompletion: { _ in })

        // When
        viewModel.saveChallenges([])

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_step" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_features")
    }

    func test_saveFeatures_tracks_skip_event_for_challenges_questions() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", analytics: analytics, onCompletion: { _ in })

        // When
        viewModel.saveFeatures([])

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_profiler_question_skipped" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_features")
    }
}
