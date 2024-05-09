import XCTest
import protocol WooFoundation.Analytics
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
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        onCompletion: {},
                                                                        uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCase(siteID: 123))
        XCTAssertEqual(viewModel.currentQuestion, .sellingStatus)

        // When
        viewModel.saveSellingStatus(nil)

        // Then
        XCTAssertEqual(viewModel.currentQuestion, .category)
    }

    func test_saveSellingStatus_saves_answer() throws {
        // Given
        let usecase = MockStoreCreationProfilerUploadAnswersUseCase()
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        onCompletion: {},
                                                                        uploadAnswersUseCase: usecase)
        // When
        viewModel.saveSellingStatus(.init(sellingStatus: .alreadySellingOnline,
                                          sellingPlatforms: [.bigCartel, .bigCommerce]))

        // Then
        let data = try XCTUnwrap(usecase.storedAnswers)
        XCTAssertEqual(data.sellingStatus, .alreadySellingOnline)
        XCTAssertEqual(data.sellingPlatforms, "big_cartel,big_commerce")
    }

    func test_saveCategory_updates_currentQuestion_to_country() {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        onCompletion: {},
                                                                        uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCase(siteID: 123))
        // When
        viewModel.saveCategory(nil)

        // Then
        XCTAssertEqual(viewModel.currentQuestion, .country)
    }

    func test_saveCategory_saves_answer() throws {
        // Given
        let usecase = MockStoreCreationProfilerUploadAnswersUseCase()
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        onCompletion: {},
                                                                        uploadAnswersUseCase: usecase)

        // When
        viewModel.saveCategory(.init(name: StoreCreationCategoryQuestionViewModel.Category.foodDrink.name,
                                     value: StoreCreationCategoryQuestionViewModel.Category.foodDrink.rawValue))


        // Then
        let data = try XCTUnwrap(usecase.storedAnswers)
        XCTAssertEqual(data.category, StoreCreationCategoryQuestionViewModel.Category.foodDrink.rawValue)
    }

    func test_saveCountry_saves_answer() throws {
        // Given
        let usecase = MockStoreCreationProfilerUploadAnswersUseCase()
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        onCompletion: {},
                                                                        uploadAnswersUseCase: usecase)
        // When
        viewModel.saveCountry(.AG)


        // Then
        let data = try XCTUnwrap(usecase.storedAnswers)
        XCTAssertEqual(data.countryCode, "AG")
    }

    func test_saveCountry_updates_currentQuestion_to_theme() {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        onCompletion: {},
                                                                        uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCase(siteID: 123))

        // When
        viewModel.saveCountry(.US)

        // Then
        XCTAssertEqual(viewModel.currentQuestion, .theme)
    }

    func test_saveTheme_schedules_theme_for_installation() throws {
        // Given
        let sampleTheme = WordPressTheme.fake().copy(id: "123")
        let themeInstaller = MockThemeInstaller()
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        onCompletion: {},
                                                                        uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCase(siteID: 123),
                                                                        themeInstaller: themeInstaller)

        // When
        viewModel.saveTheme(sampleTheme)

        // Then
        XCTAssertEqual(themeInstaller.themeIDScheduledForInstall, sampleTheme.id)
    }

    func test_saveTheme_triggers_onCompletion() throws {
        // Given
        var triggeredCompletion = false
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        onCompletion: { triggeredCompletion = true },
                                                                        uploadAnswersUseCase: MockStoreCreationProfilerUploadAnswersUseCase())

        // When
        viewModel.saveTheme(nil)

        // Then
        XCTAssertTrue(triggeredCompletion)
    }

    // MARK: - `backtrackOrDismissProfiler`

    func test_backtrackOrDismissProfiler_triggers_completionHandler_if_current_question_is_selling_status() {
        // Given
        var triggeredCompletion = false
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        onCompletion: {
            triggeredCompletion = true
        },
                                                                        uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCase(siteID: 123))
        XCTAssertEqual(viewModel.currentQuestion, .sellingStatus)

        // When
        viewModel.backtrackOrDismissProfiler()

        // Then
        XCTAssertTrue(triggeredCompletion)
    }

    func test_backtrackOrDismissProfiler_sets_current_question_to_selling_status_if_current_question_is_category() {
        // Given
        var triggeredCompletion = false
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        onCompletion: { triggeredCompletion = true },
                                                                        uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCase(siteID: 123))
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
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        onCompletion: { triggeredCompletion = true },
                                                                        uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCase(siteID: 123))
        viewModel.saveCategory(nil)

        // When
        viewModel.backtrackOrDismissProfiler()

        // Then
        XCTAssertFalse(triggeredCompletion)
        XCTAssertEqual(viewModel.currentQuestion, .category)
    }

    // MARK: - Analytics

    func test_onAppear_tracks_site_creation_event_for_selling_status_question() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        analytics: analytics,
                                                                        onCompletion: {},
                                                                        uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCase(siteID: 123))

        // When
        viewModel.onAppear()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_step" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_commerce_journey")
    }

    func test_saveSellingStatus_tracks_skip_event_for_selling_status_question() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        analytics: analytics,
                                                                        onCompletion: {},
                                                                        uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCase(siteID: 123))

        // When
        viewModel.saveSellingStatus(nil)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_profiler_question_skipped" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_commerce_journey")
    }

    func test_saveSellingStatus_tracks_skip_event_for_selling_platform_question() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        analytics: analytics,
                                                                        onCompletion: {},
                                                                        uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCase(siteID: 123))

        // When
        viewModel.saveSellingStatus(.init(sellingStatus: .alreadySellingOnline, sellingPlatforms: nil))

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_profiler_question_skipped" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_ecommerce_platforms")
    }

    func test_saveSellingStatus_tracks_site_creation_event_for_category_question() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        analytics: analytics,
                                                                        onCompletion: {},
                                                                        uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCase(siteID: 123))

        // When
        viewModel.saveSellingStatus(.init(sellingStatus: .alreadySellingOnline, sellingPlatforms: nil))

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_step" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_industries")
    }

    func test_saveCategory_tracks_skip_event_for_category_question() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        analytics: analytics,
                                                                        onCompletion: {},
                                                                        uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCase(siteID: 123))

        // When
        viewModel.saveCategory(nil)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_profiler_question_skipped" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_industries")
    }

    func test_saveCategory_tracks_site_creation_event_for_country_question() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        analytics: analytics,
                                                                        onCompletion: {},
                                                                        uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCase(siteID: 123))

        // When
        viewModel.saveCategory(nil)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_step" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["step"] as? String, "store_profiler_country")
    }

    func test_profiler_data_is_tracked_onCompletion() throws {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: 123,
                                                                        storeName: "Test",
                                                                        analytics: analytics,
                                                                        onCompletion: {},
                                                                        uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCase(siteID: 123))

        // When
        viewModel.saveSellingStatus(.init(sellingStatus: .alreadySellingOnline,
                                          sellingPlatforms: [StoreCreationSellingPlatformsQuestionViewModel.Platform.bigCartel]))
        viewModel.saveCategory(.init(name: StoreCreationCategoryQuestionViewModel.Category.clothingAccessories.name,
                                     value: StoreCreationCategoryQuestionViewModel.Category.clothingAccessories.rawValue))
        viewModel.saveCountry(.US)
        viewModel.saveTheme(nil)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "site_creation_profiler_data" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["industry_slug"] as? String, "clothing_and_accessories")
        XCTAssertEqual(eventProperties["user_commerce_journey"] as? String, "im_already_selling")
        XCTAssertEqual(eventProperties["ecommerce_platforms"] as? String, "big_cartel")
        XCTAssertEqual(eventProperties["country_code"] as? String, "US")
    }
}
