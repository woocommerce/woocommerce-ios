import XCTest
@testable import WooCommerce
@testable import Yosemite

final class BlazeBudgetSettingViewModelTests: XCTestCase {
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

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

    func test_formattedAmountAndDuration_is_updated_correctly_depending_on_hasEndDate() {
        // Given
        let initialStartDate = Date(timeIntervalSinceNow: 0)
        let viewModel = BlazeBudgetSettingViewModel(siteID: 123,
                                                    dailyBudget: 11,
                                                    isEvergreen: false,
                                                    duration: 3,
                                                    startDate: initialStartDate) { _, _, _, _ in }

        // Then
        XCTAssertEqual(viewModel.formattedAmountAndDuration.string, "$33 USD for 3 days") // total spend for 3 days

        // When
        viewModel.hasEndDate = false

        // Then
        XCTAssertEqual(viewModel.formattedAmountAndDuration.string, "$77 USD weekly spend") // weekly spend
    }

    func test_formatDayCount_returns_correct_content() {
        // Given
        let initialStartDate = Date(timeIntervalSinceNow: 0)
        let viewModel = BlazeBudgetSettingViewModel(siteID: 123,
                                                    dailyBudget: 11,
                                                    isEvergreen: false,
                                                    duration: 3,
                                                    startDate: initialStartDate) { _, _, _, _ in }

        // When
        let content = viewModel.formatDayCount(3).string

        // Then
        let endDate = initialStartDate.addingDays(3).toString(dateStyle: .medium, timeStyle: .none)
        XCTAssertEqual(content, "3 days to \(endDate)")
    }

    func test_confirmSettings_triggers_onCompletion_with_updated_details() {
        // Given
        let initialStartDate = Date(timeIntervalSinceNow: 0)
        let expectedStartDate = Date(timeIntervalSinceNow: 86400) // Next day
        var finalDailyBudget: Double?
        var finalIsEverGreen: Bool?
        var finalDuration: Int?
        var finalStartDate: Date?
        let viewModel = BlazeBudgetSettingViewModel(siteID: 123,
                                                    dailyBudget: 11,
                                                    isEvergreen: true,
                                                    duration: 3,
                                                    startDate: initialStartDate) { dailyBudget, isEvergreen, duration, startDate in
            finalDuration = duration
            finalIsEverGreen = isEvergreen
            finalDailyBudget = dailyBudget
            finalStartDate = startDate
        }

        // When
        viewModel.hasEndDate = true
        viewModel.dailyAmount = 80
        viewModel.didTapApplyDuration(dayCount: 7, since: expectedStartDate)
        viewModel.confirmSettings()

        // Then
        XCTAssertEqual(finalIsEverGreen, false)
        XCTAssertEqual(finalDailyBudget, 80)
        XCTAssertEqual(finalDuration, 7)
        XCTAssertEqual(finalStartDate, expectedStartDate)
    }

    @MainActor
    func test_updateImpressions_sends_the_correct_isEvergreen_value() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = BlazeBudgetSettingViewModel(siteID: 123,
                                                    dailyBudget: 15,
                                                    isEvergreen: true,
                                                    duration: 3,
                                                    startDate: .now,
                                                    locale: Locale(identifier: "en_US"),
                                                    stores: stores,
                                                    onCompletion: { _, _, _, _ in })

        // When
        var isEvergreenValue: Bool?
        let expectedImpression = BlazeImpressions(totalImpressionsMin: 1000, totalImpressionsMax: 5000)
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .fetchForecastedImpressions(_, input, onCompletion):
                isEvergreenValue = input.isEvergreen
                onCompletion(.success(expectedImpression))
            default:
                break
            }
        }
        await viewModel.updateImpressions(startDate: .now, dayCount: 3, dailyBudget: 15)

        // Then
        XCTAssertEqual(isEvergreenValue, true)
    }

    @MainActor
    func test_updateImpressions_updates_forecastedImpressionState_correctly_when_fetching_impression_succeeds() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = BlazeBudgetSettingViewModel(siteID: 123,
                                                    dailyBudget: 15,
                                                    isEvergreen: true,
                                                    duration: 3,
                                                    startDate: .now,
                                                    locale: Locale(identifier: "en_US"),
                                                    stores: stores,
                                                    onCompletion: { _, _, _, _ in })

        // When
        let expectedImpression = BlazeImpressions(totalImpressionsMin: 1000, totalImpressionsMax: 5000)
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .fetchForecastedImpressions(_, _, onCompletion):
                XCTAssertEqual(viewModel.forecastedImpressionState, .loading)
                onCompletion(.success(expectedImpression))
            default:
                break
            }
        }
        await viewModel.updateImpressions(startDate: .now, dayCount: 3, dailyBudget: 15)

        // Then
        XCTAssertEqual(viewModel.forecastedImpressionState, .result(formattedResult: "1,000 - 5,000"))
    }

    @MainActor
    func test_updateImpressions_updates_forecastedImpressionState_correctly_when_fetching_impression_fails() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = BlazeBudgetSettingViewModel(siteID: 123,
                                                    dailyBudget: 15,
                                                    isEvergreen: true,
                                                    duration: 3,
                                                    startDate: .now,
                                                    stores: stores,
                                                    onCompletion: { _, _, _, _ in })

        // When
        let expectedError = NSError(domain: "Test", code: 500)
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .fetchForecastedImpressions(_, _, onCompletion):
                XCTAssertEqual(viewModel.forecastedImpressionState, .loading)
                onCompletion(.failure(expectedError))
            default:
                break
            }
        }
        await viewModel.updateImpressions(startDate: .now, dayCount: 3, dailyBudget: 15)

        // Then
        XCTAssertEqual(viewModel.forecastedImpressionState, .failure)
    }

    @MainActor
    func test_retryFetchingImpressions_requests_fetching_impression_with_latest_settings() async throws {
        // Given
        var fetchInput: BlazeForecastedImpressionsInput?
        let expectedStartDate = Date(timeIntervalSinceNow: 86400) // Next day
        let timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/London"))
        let targetOptions = BlazeTargetOptions(locations: [11, 22], languages: ["en", "vi"], devices: nil, pageTopics: ["Entertainment"])
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = BlazeBudgetSettingViewModel(siteID: 123,
                                                    dailyBudget: 15,
                                                    isEvergreen: true,
                                                    duration: 3,
                                                    startDate: .now,
                                                    timeZone: timeZone,
                                                    targetOptions: targetOptions,
                                                    stores: stores,
                                                    onCompletion: { _, _, _, _ in })

        // When
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .fetchForecastedImpressions(_, input, onCompletion):
                fetchInput = input
                onCompletion(.success(.fake()))
            default:
                break
            }
        }
        viewModel.dailyAmount = 20
        viewModel.didTapApplyDuration(dayCount: 7, since: expectedStartDate)
        await viewModel.retryFetchingImpressions()

        // Then
        XCTAssertEqual(fetchInput?.startDate, expectedStartDate)
        XCTAssertEqual(fetchInput?.endDate, Date(timeInterval: 7 * 86400, since: expectedStartDate))
        XCTAssertEqual(fetchInput?.totalBudget, 20 * 7)
        XCTAssertEqual(fetchInput?.timeZone, "Europe/London")
        XCTAssertEqual(fetchInput?.targeting, targetOptions)
    }

    // MARK: Analytics

    func test_confirmSettings_tracks_event_with_correct_properties() throws {
        // Given
        let viewModel = BlazeBudgetSettingViewModel(siteID: 123,
                                                    dailyBudget: 15,
                                                    isEvergreen: true,
                                                    duration: 3,
                                                    startDate: .now,
                                                    analytics: analytics,
                                                    onCompletion: { _, _, _, _ in })


        // When
        viewModel.hasEndDate = false
        viewModel.confirmSettings()

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "blaze_creation_edit_budget_save_tapped"))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        XCTAssertEqual(eventProperties["duration"] as? Int, 3)
        XCTAssertEqual(eventProperties["total_budget"] as? Double, 45.0)
        XCTAssertEqual(eventProperties["campaign_type"] as? String, "evergreen")

        // When
        viewModel.hasEndDate = true
        viewModel.confirmSettings()

        // Then
        let lastIndex = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(of: "blaze_creation_edit_budget_save_tapped"))
        let lastEventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[lastIndex])
        XCTAssertEqual(lastEventProperties["duration"] as? Int, 3)
        XCTAssertEqual(lastEventProperties["total_budget"] as? Double, 45.0)
        XCTAssertEqual(lastEventProperties["campaign_type"] as? String, "start_end")
    }

    func test_changing_schedule_tracks_event_with_correct_properties() throws {
        // Given
        let viewModel = BlazeBudgetSettingViewModel(siteID: 123,
                                                    dailyBudget: 15,
                                                    isEvergreen: true,
                                                    duration: 3,
                                                    startDate: .now,
                                                    analytics: analytics,
                                                    onCompletion: { _, _, _, _ in })


        // When
        viewModel.didTapApplyDuration(dayCount: 7, since: .now)

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "blaze_creation_edit_budget_set_duration_applied"))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        XCTAssertEqual(eventProperties["duration"] as? Int, 7)
        XCTAssertEqual(eventProperties["campaign_type"] as? String, "evergreen")

        // When
        viewModel.hasEndDate = true
        viewModel.didTapApplyDuration(dayCount: 7, since: .now)

        // Then
        let lastIndex = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(of: "blaze_creation_edit_budget_set_duration_applied"))
        let lastEventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[lastIndex])
        XCTAssertEqual(lastEventProperties["duration"] as? Int, 7)
        XCTAssertEqual(lastEventProperties["campaign_type"] as? String, "start_end")
    }
}
