import XCTest
@testable import WooCommerce
@testable import Yosemite

@MainActor
final class BlazeBudgetSettingViewModelTests: XCTestCase {

    func test_confirmSettings_triggers_onCompletion_with_updated_details() {
        // Given
        let initialStartDate = Date(timeIntervalSinceNow: 0)
        let expectedStartDate = Date(timeIntervalSinceNow: 86400) // Next day
        var finalDailyBudget: Double?
        var finalDuration: Int?
        var finalStartDate: Date?
        let viewModel = BlazeBudgetSettingViewModel(siteID: 123,
                                                    dailyBudget: 11,
                                                    duration: 3,
                                                    startDate: initialStartDate) { dailyBudget, duration, startDate in
            finalDuration = duration
            finalDailyBudget = dailyBudget
            finalStartDate = startDate
        }

        // When
        viewModel.dailyAmount = 80
        viewModel.dayCount = 7
        viewModel.startDate = expectedStartDate
        viewModel.confirmSettings()

        // Then
        XCTAssertEqual(finalDailyBudget, 80)
        XCTAssertEqual(finalDuration, 7)
        XCTAssertEqual(finalStartDate, expectedStartDate)
    }

    func test_updateImpressions_updates_forecastedImpressionState_correctly_when_fetching_impression_succeeds() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = BlazeBudgetSettingViewModel(siteID: 123,
                                                    dailyBudget: 15,
                                                    duration: 3,
                                                    startDate: .now,
                                                    stores: stores,
                                                    onCompletion: { _, _, _ in })

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
        XCTAssertEqual(viewModel.forecastedImpressionState, .result(formattedResult: "1000 - 5000"))
    }

    func test_updateImpressions_updates_forecastedImpressionState_correctly_when_fetching_impression_fails() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = BlazeBudgetSettingViewModel(siteID: 123,
                                                    dailyBudget: 15,
                                                    duration: 3,
                                                    startDate: .now,
                                                    stores: stores,
                                                    onCompletion: { _, _, _ in })

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

    func test_retryFetchingImpressions_requests_fetching_impression_with_latest_settings() async throws {
        // Given
        var fetchInput: BlazeForecastedImpressionsInput?
        let expectedStartDate = Date(timeIntervalSinceNow: 86400) // Next day
        let timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/London"))
        let targetOptions = BlazeTargetOptions(locations: [11, 22], languages: ["en", "vi"], devices: nil, pageTopics: ["Entertainment"])
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = BlazeBudgetSettingViewModel(siteID: 123,
                                                    dailyBudget: 15,
                                                    duration: 3,
                                                    startDate: .now,
                                                    timeZone: timeZone,
                                                    targetOptions: targetOptions,
                                                    stores: stores,
                                                    onCompletion: { _, _, _ in })

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
        viewModel.dayCount = 7
        viewModel.startDate = expectedStartDate
        await viewModel.retryFetchingImpressions()

        // Then
        XCTAssertEqual(fetchInput?.startDate, expectedStartDate)
        XCTAssertEqual(fetchInput?.endDate, Date(timeInterval: 7 * 86400, since: expectedStartDate))
        XCTAssertEqual(fetchInput?.totalBudget, 20 * 7)
        XCTAssertEqual(fetchInput?.timeZone, "Europe/London")
        XCTAssertEqual(fetchInput?.targeting, targetOptions)
    }
}
