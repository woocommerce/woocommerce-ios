import Codegen
import Combine
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
import XCTest
import Yosemite
import WooFoundation
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
        let dateString = StatsStoreV4.buildDateString(from: defaultDate, with: .day)
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
        let dateString = StatsStoreV4.buildDateString(from: defaultDate, with: .day)
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
                                      intervals: [ .fake().copy(subtotals: .fake().copy(totalOrders: 3, grossRevenue: 62.7)) ])
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
                                      intervals: [ .fake().copy(subtotals: .fake().copy(totalOrders: 3, grossRevenue: 62.7)) ])
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

    // MARK: - `visitorStatsViewState`

    func test_visitorStatsViewState_for_today_is_redacted_when_selecting_interval() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        var viewStates: [StoreStatsDataOrRedactedView.State] = []
        viewModel.visitorStatsViewState.sink { viewState in
            viewStates.append(viewState)
        }.store(in: &cancellables)

        XCTAssertEqual(viewStates, [.data])

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59")])
        insertOrderStats(orderStats, timeRange: timeRange)

        XCTAssertEqual(viewStates, [.data])

        viewModel.selectedIntervalIndex = 0

        // Then
        XCTAssertEqual(viewStates, [.data, .redacted])
    }

    func test_visitorStatsViewState_for_thisWeek_is_not_redacted_when_selecting_interval() {
        let timeRange: StatsTimeRangeV4 = .thisWeek
        let viewModel = createViewModel(timeRange: timeRange)
        var viewStates: [StoreStatsDataOrRedactedView.State] = []
        viewModel.visitorStatsViewState.sink { viewState in
            viewStates.append(viewState)
        }.store(in: &cancellables)

        XCTAssertEqual(viewStates, [.data])

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59")])
        insertOrderStats(orderStats, timeRange: timeRange)

        XCTAssertEqual(viewStates, [.data])

        viewModel.selectedIntervalIndex = 0

        // Then
        XCTAssertEqual(viewStates, [.data])
    }

    func test_visitorStatsViewState_is_redactedDueToJetpack_when_siteVisitStatsMode_is_redactedDueToJetpack() {
        let timeRange: StatsTimeRangeV4 = .thisWeek
        let viewModel = createViewModel(timeRange: timeRange)
        var viewStates: [StoreStatsDataOrRedactedView.State] = []
        viewModel.visitorStatsViewState.sink { viewState in
            viewStates.append(viewState)
        }.store(in: &cancellables)

        XCTAssertEqual(viewStates, [.data])

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59")])
        insertOrderStats(orderStats, timeRange: timeRange)

        XCTAssertEqual(viewStates, [.data])

        viewModel.siteVisitStatsMode = .redactedDueToJetpack

        // Then
        XCTAssertEqual(viewStates, [.data, .redactedDueToJetpack])

        viewModel.selectedIntervalIndex = 0
        XCTAssertEqual(viewStates, [.data, .redactedDueToJetpack])
    }

    func test_visitorStatsViewState_is_redacted_when_siteVisitStatsMode_is_hidden() {
        let timeRange: StatsTimeRangeV4 = .thisWeek
        let viewModel = createViewModel(timeRange: timeRange)
        var viewStates: [StoreStatsDataOrRedactedView.State] = []
        viewModel.visitorStatsViewState.sink { viewState in
            viewStates.append(viewState)
        }.store(in: &cancellables)

        XCTAssertEqual(viewStates, [.data])

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59")])
        insertOrderStats(orderStats, timeRange: timeRange)

        XCTAssertEqual(viewStates, [.data])

        viewModel.siteVisitStatsMode = .hidden

        // Then
        XCTAssertEqual(viewStates, [.data, .redacted])

        viewModel.selectedIntervalIndex = 0
        XCTAssertEqual(viewStates, [.data, .redacted])
    }

    // MARK: - `conversionStatsViewState`

    func test_conversionStatsViewState_for_today_is_redacted_when_selecting_interval() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        var viewStates: [StoreStatsDataOrRedactedView.State] = []
        viewModel.conversionStatsViewState.sink { viewState in
            viewStates.append(viewState)
        }.store(in: &cancellables)

        XCTAssertEqual(viewStates, [.data])

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59")])
        insertOrderStats(orderStats, timeRange: timeRange)

        XCTAssertEqual(viewStates, [.data])

        viewModel.selectedIntervalIndex = 0

        // Then
        XCTAssertEqual(viewStates, [.data, .redacted])
    }

    func test_conversionStatsViewState_for_thisWeek_is_not_redacted_when_selecting_interval() {
        let timeRange: StatsTimeRangeV4 = .thisWeek
        let viewModel = createViewModel(timeRange: timeRange)
        var viewStates: [StoreStatsDataOrRedactedView.State] = []
        viewModel.conversionStatsViewState.sink { viewState in
            viewStates.append(viewState)
        }.store(in: &cancellables)

        XCTAssertEqual(viewStates, [.data])

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59")])
        insertOrderStats(orderStats, timeRange: timeRange)

        XCTAssertEqual(viewStates, [.data])

        viewModel.selectedIntervalIndex = 0

        // Then
        XCTAssertEqual(viewStates, [.data])
    }

    func test_conversionStatsViewState_is_redacted_when_siteVisitStatsMode_is_redactedDueToJetpack() {
        let timeRange: StatsTimeRangeV4 = .thisWeek
        let viewModel = createViewModel(timeRange: timeRange)
        var viewStates: [StoreStatsDataOrRedactedView.State] = []
        viewModel.conversionStatsViewState.sink { viewState in
            viewStates.append(viewState)
        }.store(in: &cancellables)

        XCTAssertEqual(viewStates, [.data])

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59")])
        insertOrderStats(orderStats, timeRange: timeRange)

        XCTAssertEqual(viewStates, [.data])

        viewModel.siteVisitStatsMode = .redactedDueToJetpack

        // Then
        XCTAssertEqual(viewStates, [.data, .redacted])

        viewModel.selectedIntervalIndex = 0
        XCTAssertEqual(viewStates, [.data, .redacted])
    }

    func test_conversionStatsViewState_is_redacted_when_siteVisitStatsMode_is_hidden() {
        let timeRange: StatsTimeRangeV4 = .thisWeek
        let viewModel = createViewModel(timeRange: timeRange)
        var viewStates: [StoreStatsDataOrRedactedView.State] = []
        viewModel.conversionStatsViewState.sink { viewState in
            viewStates.append(viewState)
        }.store(in: &cancellables)

        XCTAssertEqual(viewStates, [.data])

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59")])
        insertOrderStats(orderStats, timeRange: timeRange)

        XCTAssertEqual(viewStates, [.data])

        viewModel.siteVisitStatsMode = .hidden

        // Then
        XCTAssertEqual(viewStates, [.data, .redacted])

        viewModel.selectedIntervalIndex = 0
        XCTAssertEqual(viewStates, [.data, .redacted])
    }

    // MARK: - `yAxisMaximum` and `yAxisMinimum`

    func test_yAxisMaximum_and_yAxisMaximum_are_1_and_minus_1_when_there_is_no_revenue() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        var yAxisMaximumValues: [Double] = []
        viewModel.yAxisMaximum.sink { yAxisMaximum in
            yAxisMaximumValues.append(yAxisMaximum)
        }.store(in: &cancellables)

        var yAxisMinimumValues: [Double] = []
        viewModel.yAxisMinimum.sink { yAxisMinimum in
            yAxisMinimumValues.append(yAxisMinimum)
        }.store(in: &cancellables)

        XCTAssertEqual(yAxisMaximumValues, [1])
        XCTAssertEqual(yAxisMinimumValues, [-1])

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 0),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59",
                                                               subtotals: .fake().copy(grossRevenue: 0))])
        insertOrderStats(orderStats, timeRange: timeRange)

        // Then
        XCTAssertEqual(yAxisMaximumValues, [1])
        XCTAssertEqual(yAxisMinimumValues, [-1])
    }

    func test_yAxisMaximum_is_the_next_higher_power_of_ten_when_max_revenue_is_in_the_10s() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        var yAxisMaximumValues: [Double] = []
        viewModel.yAxisMaximum.dropFirst().sink { yAxisMaximum in
            yAxisMaximumValues.append(yAxisMaximum)
        }.store(in: &cancellables)

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 0),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59",
                                                               subtotals: .fake().copy(grossRevenue: 68)),
                                                  .fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59",
                                                               subtotals: .fake().copy(grossRevenue: 25))])
        insertOrderStats(orderStats, timeRange: timeRange)

        // Then
        XCTAssertEqual(yAxisMaximumValues, [70])
    }

    func test_yAxisMaximum_is_0_when_revenue_is_all_negative() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        var yAxisMaximumValues: [Double] = []
        viewModel.yAxisMaximum.dropFirst().sink { yAxisMaximum in
            yAxisMaximumValues.append(yAxisMaximum)
        }.store(in: &cancellables)

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 0),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59",
                                                               subtotals: .fake().copy(grossRevenue: -2)),
                                                  .fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59",
                                                               subtotals: .fake().copy(grossRevenue: -61))])
        insertOrderStats(orderStats, timeRange: timeRange)

        // Then
        XCTAssertEqual(yAxisMaximumValues, [0])
    }

    func test_yAxisMinimum_is_0_when_min_revenue_is_positive() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        var yAxisMinimumValues: [Double] = []
        viewModel.yAxisMinimum.dropFirst().sink { yAxisMinimum in
            yAxisMinimumValues.append(yAxisMinimum)
        }.store(in: &cancellables)

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 0),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59",
                                                               subtotals: .fake().copy(grossRevenue: 68)),
                                                  .fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59",
                                                               subtotals: .fake().copy(grossRevenue: 2))])
        insertOrderStats(orderStats, timeRange: timeRange)

        // Then
        XCTAssertEqual(yAxisMinimumValues, [0])
    }

    func test_yAxisMinimum_is_the_next_lower_power_of_ten_when_min_revenue_is_in_the_negative_10s() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        var yAxisMinimumValues: [Double] = []
        viewModel.yAxisMinimum.dropFirst().sink { yAxisMinimum in
            yAxisMinimumValues.append(yAxisMinimum)
        }.store(in: &cancellables)

        // When
        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 0),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59",
                                                               subtotals: .fake().copy(grossRevenue: 68)),
                                                  .fake().copy(dateStart: "2022-01-03 00:00:00",
                                                               dateEnd: "2022-01-03 23:59:59",
                                                               subtotals: .fake().copy(grossRevenue: -61))])
        insertOrderStats(orderStats, timeRange: timeRange)

        // Then
        XCTAssertEqual(yAxisMinimumValues, [-70])
    }
}

private extension StoreStatsPeriodViewModelTests {
    func createViewModel(timeRange: StatsTimeRangeV4) -> StoreStatsPeriodViewModel {
        StoreStatsPeriodViewModel(siteID: siteID,
                                  timeRange: timeRange,
                                  siteTimezone: defaultSiteTimezone,
                                  currentDate: defaultDate,
                                  currencyFormatter: currencyFormatter,
                                  currencySettings: currencySettings,
                                  storageManager: storageManager)
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
