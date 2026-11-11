import Foundation
import Testing
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
struct StorePerformanceViewModelDayRolloverTests {
    private let siteID: Int64 = 123
    private let storageManager = MockStorageManager()

    @Test func visitorStatsText_when_a_refresh_after_midnight_stores_the_new_days_summary_then_shows_the_new_days_visitors() async throws {
        // Given
        let firstDay = Date(timeIntervalSince1970: 1_790_000_000)
        let nextDay = firstDay.addingTimeInterval(24 * 60 * 60)
        var currentDate = firstDay

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stubStatsActions(stores: stores, onSummaryRetrieved: { [self] in
            if currentDate == nextDay {
                insertSummaryStats(visitors: 468, on: currentDate)
            }
        })
        let viewModel = StorePerformanceViewModel(siteID: siteID,
                                                  siteTimezone: .current,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  usageTracksEventEmitter: .init(),
                                                  now: { currentDate })
        insertSummaryStats(visitors: 351, on: firstDay)
        viewModel.didSelectTimeRange(.today)
        await viewModel.reloadDataIfNeeded(forceRefresh: true)
        try #require(viewModel.visitorStatsText == "351")

        // When
        currentDate = nextDay
        await viewModel.reloadDataIfNeeded(forceRefresh: true)

        // Then
        #expect(viewModel.visitorStatsText == "468")
    }
}

private extension StorePerformanceViewModelDayRolloverTests {
    func stubStatsActions(stores: MockStoresManager, onSummaryRetrieved: @escaping () -> Void) {
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveStats(_, _, _, _, _, _, _, onCompletion):
                onCompletion(.success(()))
            case let .retrieveSiteVisitStats(_, _, _, _, onCompletion):
                onCompletion(.success(()))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, onCompletion):
                onSummaryRetrieved()
                onCompletion(.success(.fake()))
            default:
                break
            }
        }
    }

    func insertSummaryStats(visitors: Int, on date: Date) {
        let dateString = StatsStoreV4.buildDateString(from: date, timeRange: .today)
        let stats = SiteSummaryStats.fake().copy(siteID: siteID, date: dateString, visitors: visitors)
        let storage = storageManager.viewStorage
        let storageStats = storage.insertNewObject(ofType: StorageSiteSummaryStats.self)
        storageStats.period = StatsTimeRangeV4.today.summaryStatsGranularity.rawValue
        storageStats.update(with: stats)
        storage.saveIfNeeded()
    }
}
