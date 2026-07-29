import Codegen
import Combine
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
import XCTest
import Yosemite
import WooFoundation
import YosemiteTestHelpers
@testable import WooCommerce

final class StoreStatsPeriodViewModelTests: XCTestCase {
    private let siteID: Int64 = 300
    private let defaultSiteTimezone = TimeZone(identifier: "GMT") ?? .current
    private let defaultDate = Date(timeIntervalSince1970: 1671123600) // Dec 15, 2022, 5:00:00 PM GMT
    private var storageManager: StorageManagerType!
    private var storage: StorageType {
        storageManager.viewStorage
    }
    private let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Default is US.
    private let currencySettings = CurrencySettings() // Default is US.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - For testing observable's emitted values
    private var orderStatsTextValues: [String] = []
    private var revenueStatsTextValues: [String] = []
    private var visitorStatsTextValues: [String] = []
    private var conversionStatsTextValues: [String] = []

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        resetStatsEmittedValues()
    }

    override func tearDown() {
        storageManager = nil

        cancellables.forEach {
            $0.cancel()
        }
        cancellables.removeAll()

        super.tearDown()
    }

    func test_orderStatsText_and_revenueStatsText_are_emitted_after_order_stats_updated() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        observeStatsEmittedValues(viewModel: viewModel)

        XCTAssertEqual(orderStatsTextValues, ["-"])
        XCTAssertEqual(revenueStatsTextValues, ["-"])
        XCTAssertEqual(visitorStatsTextValues, ["-"])
        XCTAssertEqual(conversionStatsTextValues, ["-"])

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 6220.7),
                                      intervals: [.fake()])
        insertOrderStats(orderStats, timeRange: timeRange)

        // Then
        XCTAssertEqual(orderStatsTextValues, ["-", "3"])
        XCTAssertEqual(revenueStatsTextValues, ["-", "$6,220.70"])
        XCTAssertEqual(visitorStatsTextValues, ["-"])
        XCTAssertEqual(conversionStatsTextValues, ["-"])
    }

    func test_visitorStatsText_is_emitted_after_summary_stats_updated() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        observeStatsEmittedValues(viewModel: viewModel)

        XCTAssertEqual(orderStatsTextValues, ["-"])
        XCTAssertEqual(revenueStatsTextValues, ["-"])
        XCTAssertEqual(visitorStatsTextValues, ["-"])
        XCTAssertEqual(conversionStatsTextValues, ["-"])

        // When
        let dateString = StatsStoreV4.buildDateString(from: defaultDate, timeRange: .today)
        let siteSummaryStats = Yosemite.SiteSummaryStats.fake().copy(siteID: siteID, date: dateString, visitors: 22)
        insertSiteSummaryStats(siteSummaryStats, timeRange: timeRange)

        // Then
        XCTAssertEqual(orderStatsTextValues, ["-"])
        XCTAssertEqual(revenueStatsTextValues, ["-"])
        XCTAssertEqual(visitorStatsTextValues, ["-", "22"])
        XCTAssertEqual(conversionStatsTextValues, ["-"])
    }

    func test_visitorStatsText_is_not_emitted_for_time_range_with_inequivalent_granularities_of_order_and_visit_stats() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        observeStatsEmittedValues(viewModel: viewModel)

        XCTAssertEqual(orderStatsTextValues, ["-"])
        XCTAssertEqual(revenueStatsTextValues, ["-"])
        XCTAssertEqual(visitorStatsTextValues, ["-"])
        XCTAssertEqual(conversionStatsTextValues, ["-"])

        // When
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(siteID: siteID, items: [ .fake().copy(visitors: 17) ])
        insertSiteVisitStats(siteVisitStats, timeRange: timeRange)

        XCTAssertEqual(visitorStatsTextValues, ["-"])

        viewModel.selectedIntervalIndex = 0

        // Then
        XCTAssertEqual(orderStatsTextValues, ["-"])
        XCTAssertEqual(revenueStatsTextValues, ["-"])
        XCTAssertEqual(visitorStatsTextValues, ["-"])
        XCTAssertEqual(conversionStatsTextValues, ["-"])
    }

    func test_visitorStatsText_is_emitted_for_time_range_with_equivalent_granularities_of_order_and_visit_stats() {
        // Given
        let timeRange: StatsTimeRangeV4 = .thisMonth
        let viewModel = createViewModel(timeRange: timeRange)
        observeStatsEmittedValues(viewModel: viewModel)

        XCTAssertEqual(orderStatsTextValues, ["-"])
        XCTAssertEqual(revenueStatsTextValues, ["-"])
        XCTAssertEqual(visitorStatsTextValues, ["-"])
        XCTAssertEqual(conversionStatsTextValues, ["-"])

        // When
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(siteID: siteID, items: [ .fake().copy(visitors: 17) ])
        insertSiteVisitStats(siteVisitStats, timeRange: timeRange)

        XCTAssertEqual(visitorStatsTextValues, ["-"])

        viewModel.selectedIntervalIndex = 0

        // Then
        XCTAssertEqual(orderStatsTextValues, ["-"])
        XCTAssertEqual(revenueStatsTextValues, ["-"])
        XCTAssertEqual(visitorStatsTextValues, ["-", "17"])
        XCTAssertEqual(conversionStatsTextValues, ["-"])
    }

    func test_conversionStatsText_is_emitted_after_order_and_summary_stats_updated() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        observeStatsEmittedValues(viewModel: viewModel)

        // When
        let dateString = StatsStoreV4.buildDateString(from: defaultDate, timeRange: .today)
        let siteSummaryStats = Yosemite.SiteSummaryStats.fake().copy(siteID: siteID, date: dateString, visitors: 15)
        insertSiteSummaryStats(siteSummaryStats, timeRange: timeRange)

        XCTAssertEqual(conversionStatsTextValues, ["-"])

        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake()])
        insertOrderStats(orderStats, timeRange: timeRange)

        // Then
        XCTAssertEqual(conversionStatsTextValues, ["-", "20%"]) // order count: 3, visitor count: 15 => 0.2 (20%)
    }

    func test_conversionStatsText_is_not_emitted_for_time_range_with_inequivalent_granularities_of_order_and_visit_stats() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        observeStatsEmittedValues(viewModel: viewModel)

        // When
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(siteID: siteID, items: [.fake().copy(visitors: 15)])
        insertSiteVisitStats(siteVisitStats, timeRange: timeRange)

        XCTAssertEqual(conversionStatsTextValues, ["-"])

        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake(),
                                      intervals: [ .fake().copy(dateStart: "2022-01-03 00:00:00",
                                                                 subtotals: .fake().copy(totalOrders: 3, grossRevenue: 62.7)) ])
        insertOrderStats(orderStats, timeRange: timeRange)

        XCTAssertEqual(conversionStatsTextValues, ["-"])

        viewModel.selectedIntervalIndex = 0

        // Then
        XCTAssertEqual(conversionStatsTextValues, ["-"])
    }

    func test_conversionStatsText_is_emitted_for_time_range_with_equivalent_granularities_of_order_and_visit_stats() {
        // Given
        let timeRange: StatsTimeRangeV4 = .thisMonth
        let viewModel = createViewModel(timeRange: timeRange)
        observeStatsEmittedValues(viewModel: viewModel)

        // When
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(siteID: siteID, items: [.fake().copy(visitors: 15)])
        insertSiteVisitStats(siteVisitStats, timeRange: timeRange)

        XCTAssertEqual(conversionStatsTextValues, ["-"])

        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake(),
                                      intervals: [ .fake().copy(dateStart: "2022-01-03 00:00:00",
                                                                 subtotals: .fake().copy(totalOrders: 3, grossRevenue: 62.7)) ])
        insertOrderStats(orderStats, timeRange: timeRange)

        XCTAssertEqual(conversionStatsTextValues, ["-"])

        viewModel.selectedIntervalIndex = 0

        // Then
        XCTAssertEqual(conversionStatsTextValues, ["-", "20%"]) // order count: 3, visitor count: 15 => 0.2 (20%)
    }

    // MARK: `StatsTimeRangeBarViewModel`

    func test_timeRangeBarViewModel_for_today_is_emitted_twice_after_order_and_visitor_stats_updated_and_selecting_interval() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        var timeRangeBarViewModels: [StatsTimeRangeBarViewModel] = []
        viewModel.timeRangeBarViewModel.sink { viewModel in
            timeRangeBarViewModels.append(viewModel)
        }.store(in: &cancellables)

        XCTAssertEqual(timeRangeBarViewModels, [])

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 01:00:00",
                                                               dateEnd: "2022-01-03 01:59:59")])
        insertOrderStats(orderStats, timeRange: timeRange)

        XCTAssertEqual(timeRangeBarViewModels.map { $0.timeRangeText }, ["Monday, Jan 3"])

        viewModel.selectedIntervalIndex = 0

        // Then
        if #available(iOS 16.0, *) {
            XCTAssertEqual(timeRangeBarViewModels.map { $0.timeRangeText }, ["Monday, Jan 3", "Monday, Jan 3 at 1:00 AM"])
        } else {
            XCTAssertEqual(timeRangeBarViewModels.map { $0.timeRangeText }, ["Monday, Jan 3", "Monday, Jan 3, 1:00 AM"])
        }
    }

    func test_timeRangeBarViewModel_for_thisWeek_is_emitted_twice_after_order_and_visitor_stats_updated_and_selecting_interval() {
        // Given
        let timeRange: StatsTimeRangeV4 = .thisWeek
        let viewModel = createViewModel(timeRange: timeRange)
        var timeRangeBarViewModels: [StatsTimeRangeBarViewModel] = []
        viewModel.timeRangeBarViewModel.sink { viewModel in
            timeRangeBarViewModels.append(viewModel)
        }.store(in: &cancellables)

        XCTAssertEqual(timeRangeBarViewModels, [])

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59"),
                                                  .fake().copy(dateStart: "2022-01-05 00:00:00",
                                                               dateEnd: "2022-01-05 23:59:59")])
        insertOrderStats(orderStats, timeRange: timeRange)

        XCTAssertEqual(timeRangeBarViewModels.map { $0.timeRangeText }, ["Jan 3 – Jan 5"])

        viewModel.selectedIntervalIndex = 1

        // Then
        XCTAssertEqual(timeRangeBarViewModels.map { $0.timeRangeText }, ["Jan 3 – Jan 5", "Jan 5"])
    }

    func test_timeRangeBarViewModel_for_thisMonth_is_emitted_twice_after_order_and_visitor_stats_updated_and_selecting_interval() {
        // Given
        let timeRange: StatsTimeRangeV4 = .thisMonth
        let viewModel = createViewModel(timeRange: timeRange)
        var timeRangeBarViewModels: [StatsTimeRangeBarViewModel] = []
        viewModel.timeRangeBarViewModel.sink { viewModel in
            timeRangeBarViewModels.append(viewModel)
        }.store(in: &cancellables)

        XCTAssertEqual(timeRangeBarViewModels, [])

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59")])
        insertOrderStats(orderStats, timeRange: timeRange)

        XCTAssertEqual(timeRangeBarViewModels.map { $0.timeRangeText }, ["January 2022"])

        viewModel.selectedIntervalIndex = 0

        // Then
        XCTAssertEqual(timeRangeBarViewModels.map { $0.timeRangeText }, ["January 2022", "Jan 3"])
    }

    func test_timeRangeBarViewModel_for_thisYear_is_emitted_twice_after_order_and_visitor_stats_updated_and_selecting_interval() {
        // Given
        let timeRange: StatsTimeRangeV4 = .thisYear
        let viewModel = createViewModel(timeRange: timeRange)
        var timeRangeBarViewModels: [StatsTimeRangeBarViewModel] = []
        viewModel.timeRangeBarViewModel.sink { viewModel in
            timeRangeBarViewModels.append(viewModel)
        }.store(in: &cancellables)

        XCTAssertEqual(timeRangeBarViewModels, [])

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59")])
        insertOrderStats(orderStats, timeRange: timeRange)

        XCTAssertEqual(timeRangeBarViewModels.map { $0.timeRangeText }, ["2022"])

        viewModel.selectedIntervalIndex = 0

        // Then
        XCTAssertEqual(timeRangeBarViewModels.map { $0.timeRangeText }, ["2022", "January 2022"])
    }

    // MARK: - `orderStatsIntervals`

    func test_orderStatsIntervals_is_emitted_once_after_order_stats_are_updated() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        var orderStatsIntervalsValues: [[OrderStatsV4Interval]] = []
        viewModel.orderStatsIntervals.sink { orderStatsIntervals in
            orderStatsIntervalsValues.append(orderStatsIntervals)
        }.store(in: &cancellables)

        XCTAssertEqual(orderStatsIntervalsValues, [[]])

        // When
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(siteID: siteID, items: [
            .fake().copy(visitors: 10),
        ])
        insertSiteVisitStats(siteVisitStats, timeRange: timeRange)

        // `orderStatsIntervals` is not emitted after visitor stats are updated.
        XCTAssertEqual(orderStatsIntervalsValues, [[]])

        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 01:00:00",
                                                               dateEnd: "2022-01-03 01:59:59",
                                                               subtotals: .fake())])
        insertOrderStats(orderStats, timeRange: timeRange)

        // `orderStatsIntervals` is emitted after order stats are updated.
        assertEqual([[], orderStats.intervals], orderStatsIntervalsValues)

        viewModel.selectedIntervalIndex = 0

        // `orderStatsIntervals` is not emitted again after visitor stats are updated.
        assertEqual([[], orderStats.intervals], orderStatsIntervalsValues)
    }

    // MARK: Revenue type

    func test_revenueStatsText_when_revenueType_changes_then_emits_value_for_new_metric() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        observeStatsEmittedValues(viewModel: viewModel)

        // When — totals expose all three revenue fields with distinct, non-integer values so the
        // formatter renders explicit decimals (it strips them when the amount is integer).
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3,
                                                           grossRevenue: 100.50, // total_sales
                                                           grossSales: 80.25,    // gross_sales
                                                           netRevenue: 60.10),
                                      intervals: [.fake()])
        insertOrderStats(orderStats, timeRange: timeRange)

        // Initially the default `.total` metric drives the text — `total_sales` is shown.
        XCTAssertEqual(revenueStatsTextValues, ["-", "$100.50"])

        // When — switch to `.gross` then `.net`.
        viewModel.revenueType = .gross
        viewModel.revenueType = .net

        // Then — each switch produces a fresh emission with the corresponding amount.
        XCTAssertEqual(revenueStatsTextValues, ["-", "$100.50", "$80.25", "$60.10"])
    }

    // MARK: - Unparseable interval dates: reporting and alignment

    func test_updateOrderData_when_an_interval_has_unparseable_date_then_reports_non_fatal_once_with_bad_date() {
        // Given
        let timeRange: StatsTimeRangeV4 = .thisMonth
        let crashLogger = MockCrashLogger()
        let viewModel = createViewModel(timeRange: timeRange, crashLogging: crashLogger)
        observeStatsEmittedValues(viewModel: viewModel)
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake(),
                                      intervals: [
                                        .fake().copy(dateStart: "", subtotals: .fake()),
                                        .fake().copy(dateStart: "2022-01-03 00:00:00", subtotals: .fake())
                                      ])

        // When
        insertOrderStats(orderStats, timeRange: timeRange)

        // Then
        XCTAssertEqual(crashLogger.loggedMessages.count, 1)
        let logged = crashLogger.loggedMessages.first
        XCTAssertEqual(logged?.properties?["dropped_interval_count"] as? Int, 1)
        XCTAssertEqual(logged?.properties?["unparseable_date_starts"] as? [String], [""])
        XCTAssertEqual(logged?.level, .error)
    }

    func test_updateOrderData_when_all_interval_dates_parse_then_does_not_report() {
        // Given
        let timeRange: StatsTimeRangeV4 = .thisMonth
        let crashLogger = MockCrashLogger()
        let viewModel = createViewModel(timeRange: timeRange, crashLogging: crashLogger)
        observeStatsEmittedValues(viewModel: viewModel)
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake(),
                                      intervals: [ .fake().copy(dateStart: "2022-01-03 00:00:00", subtotals: .fake()) ])

        // When
        insertOrderStats(orderStats, timeRange: timeRange)

        // Then
        XCTAssertTrue(crashLogger.loggedMessages.isEmpty)
    }

    func test_updateOrderData_when_an_interval_has_unparseable_date_then_tracks_unexpected_format_event() {
        // Given
        let timeRange: StatsTimeRangeV4 = .thisMonth
        let analyticsProvider = MockAnalyticsProvider()
        let viewModel = createViewModel(timeRange: timeRange,
                                        analytics: WooAnalytics(analyticsProvider: analyticsProvider))
        observeStatsEmittedValues(viewModel: viewModel)
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake(),
                                      intervals: [
                                        .fake().copy(dateStart: "", subtotals: .fake()),
                                        .fake().copy(dateStart: "2022-01-03 00:00:00", subtotals: .fake())
                                      ])

        // When
        insertOrderStats(orderStats, timeRange: timeRange)

        // Then
        let eventIndices = analyticsProvider.receivedEvents.enumerated()
            .filter { $0.element == "stats_unexpected_format" }
            .map(\.offset)
        XCTAssertEqual(eventIndices.count, 1)
        let properties = eventIndices.first.map { analyticsProvider.receivedProperties[$0] }
        XCTAssertEqual(properties?["date"] as? String, "")
    }

    func test_visitorStatsText_when_an_interval_has_unparseable_date_then_selected_visitor_count_stays_aligned() {
        // Given
        let timeRange: StatsTimeRangeV4 = .thisMonth
        let viewModel = createViewModel(timeRange: timeRange)
        observeStatsEmittedValues(viewModel: viewModel)

        // Three visit-stat items, ascending by period.
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(siteID: siteID, items: [
            .fake().copy(period: "2022-01-01", visitors: 10),
            .fake().copy(period: "2022-01-02", visitors: 20),
            .fake().copy(period: "2022-01-03", visitors: 30)
        ])
        insertSiteVisitStats(siteVisitStats, timeRange: timeRange)

        // Three order intervals; the earliest has an unparseable (empty) date and is dropped, leaving two.
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake(),
                                      intervals: [
                                        .fake().copy(dateStart: "", subtotals: .fake()),
                                        .fake().copy(dateStart: "2022-01-02 00:00:00", subtotals: .fake()),
                                        .fake().copy(dateStart: "2022-01-03 00:00:00", subtotals: .fake())
                                      ])
        insertOrderStats(orderStats, timeRange: timeRange)

        // When — select the last of the two surviving chart bars.
        viewModel.selectedIntervalIndex = 1

        // Then — visitor count is the last item (30), aligned to the filtered intervals (not the raw-count 20).
        XCTAssertEqual(visitorStatsTextValues.last, "30")
    }
}

private extension StoreStatsPeriodViewModelTests {
    func createViewModel(timeRange: StatsTimeRangeV4,
                         crashLogging: CrashLogger = MockCrashLogger(),
                         analytics: Analytics = WooAnalytics(analyticsProvider: MockAnalyticsProvider())) -> StoreStatsPeriodViewModel {
        StoreStatsPeriodViewModel(siteID: siteID,
                                  timeRange: timeRange,
                                  siteTimezone: defaultSiteTimezone,
                                  currentDate: defaultDate,
                                  currencyFormatter: currencyFormatter,
                                  currencySettings: currencySettings,
                                  storageManager: storageManager,
                                  crashLogging: crashLogging,
                                  analytics: analytics)
    }

    func observeStatsEmittedValues(viewModel: StoreStatsPeriodViewModel) {
        viewModel.orderStatsText.sink { [weak self] text in
            self?.orderStatsTextValues.append(text)
        }.store(in: &cancellables)

        viewModel.revenueStatsText.sink { [weak self] text in
            self?.revenueStatsTextValues.append(text)
        }.store(in: &cancellables)

        viewModel.visitorStatsText.sink { [weak self] text in
            self?.visitorStatsTextValues.append(text)
        }.store(in: &cancellables)

        viewModel.conversionStatsText.sink { [weak self] text in
            self?.conversionStatsTextValues.append(text)
        }.store(in: &cancellables)
    }

    func resetStatsEmittedValues() {
        orderStatsTextValues = []
        revenueStatsTextValues = []
        visitorStatsTextValues = []
        conversionStatsTextValues = []
    }

    func insertOrderStats(_ readonlyOrderStats: Yosemite.OrderStatsV4, timeRange: StatsTimeRangeV4) {
        let storageOrderStats = storage.insertNewObject(ofType: StorageOrderStatsV4.self)
        storageOrderStats.timeRange = timeRange.rawValue
        storageOrderStats.totals = storage.insertNewObject(ofType: StorageOrderStatsV4Totals.self)
        storageOrderStats.update(with: readonlyOrderStats)
        readonlyOrderStats.intervals.forEach { readOnlyInterval in
            let newStorageInterval = storage.insertNewObject(ofType: StorageOrderStatsV4Interval.self)
            newStorageInterval.subtotals = storage.insertNewObject(ofType: StorageOrderStatsV4Totals.self)
            newStorageInterval.update(with: readOnlyInterval)
            storageOrderStats.addToIntervals(newStorageInterval)
        }
        storage.saveIfNeeded()
    }

    func insertSiteVisitStats(_ readonlySiteVisitStats: Yosemite.SiteVisitStats, timeRange: StatsTimeRangeV4) {
        let storageSiteVisitStats = storage.insertNewObject(ofType: StorageSiteVisitStats.self)
        storageSiteVisitStats.timeRange = timeRange.rawValue
        storageSiteVisitStats.update(with: readonlySiteVisitStats)
        readonlySiteVisitStats.items?.forEach { readOnlyItem in
            let newStorageItem = storage.insertNewObject(ofType: StorageSiteVisitStatsItem.self)
            newStorageItem.update(with: readOnlyItem)
            storageSiteVisitStats.addToItems(newStorageItem)
        }
        storage.saveIfNeeded()
    }

    func insertSiteSummaryStats(_ readOnlySiteSummaryStats: Yosemite.SiteSummaryStats, timeRange: StatsTimeRangeV4) {
        let storageSiteSummaryStats = storage.insertNewObject(ofType: StorageSiteSummaryStats.self)
        storageSiteSummaryStats.period = timeRange.summaryStatsGranularity.rawValue
        storageSiteSummaryStats.update(with: readOnlySiteSummaryStats)
        storage.saveIfNeeded()
    }
}

/// Records `logMessage` calls so tests can assert what was reported.
private final class MockCrashLogger: CrashLogger {
    private(set) var loggedMessages: [(message: String, properties: [String: Any]?, level: SeverityLevel)] = []

    func logError(_ error: Error, userInfo: [String: Any]?, level: SeverityLevel) {}

    func logMessage(_ message: String, properties: [String: Any]?, level: SeverityLevel) {
        loggedMessages.append((message, properties, level))
    }

    func logMessageAndWait(_ message: String, properties: [String: Any]?, level: SeverityLevel) {
        loggedMessages.append((message, properties, level))
    }

    func logFatalErrorAndExit(_ error: Error, userInfo: [String: Any]?) -> Never {
        fatalError(error.localizedDescription)
    }
}
