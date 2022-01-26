import Codegen
import Combine
import Storage
import XCTest
import Yosemite
@testable import WooCommerce

final class StoreStatsPeriodViewModelTests: XCTestCase {
    private let siteID: Int64 = 300
    private let defaultSiteTimezone = TimeZone(identifier: "GMT") ?? .current
    private var storageManager: StorageManagerType!
    private var storage: StorageType {
        storageManager.viewStorage
    }
    private let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Default is US.
    private let currencyCode = CurrencySettings.CurrencyCode.USD.rawValue
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

    func test_visitorStatsText_is_emitted_after_visitor_stats_updated() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        observeStatsEmittedValues(viewModel: viewModel)

        XCTAssertEqual(orderStatsTextValues, ["-"])
        XCTAssertEqual(revenueStatsTextValues, ["-"])
        XCTAssertEqual(visitorStatsTextValues, ["-"])
        XCTAssertEqual(conversionStatsTextValues, ["-"])

        // When
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(siteID: siteID, items: [
            .fake().copy(visitors: 17),
            .fake().copy(visitors: 5)
        ])
        insertSiteVisitStats(siteVisitStats, timeRange: timeRange)

        // Then
        XCTAssertEqual(orderStatsTextValues, ["-"])
        XCTAssertEqual(revenueStatsTextValues, ["-"])
        XCTAssertEqual(visitorStatsTextValues, ["-", "22"])
        XCTAssertEqual(conversionStatsTextValues, ["-"])
    }

    func test_conversionStatsText_is_emitted_after_order_and_visitor_stats_updated() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        observeStatsEmittedValues(viewModel: viewModel)

        // When
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(siteID: siteID, items: [
            .fake().copy(visitors: 10),
            .fake().copy(visitors: 5)
        ])
        insertSiteVisitStats(siteVisitStats, timeRange: timeRange)

        XCTAssertEqual(conversionStatsTextValues, ["-"])

        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake()])
        insertOrderStats(orderStats, timeRange: timeRange)

        // Then
        XCTAssertEqual(conversionStatsTextValues, ["-", "20.0%"]) // order count: 3, visitor count: 15 => 0.2 (20%)
    }

    func test_placeholder_conversionStatsText_is_emitted_when_visitor_count_is_zero() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        observeStatsEmittedValues(viewModel: viewModel)

        // When
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(siteID: siteID, items: [
            .fake().copy(visitors: 0)
        ])
        insertSiteVisitStats(siteVisitStats, timeRange: timeRange)

        XCTAssertEqual(conversionStatsTextValues, ["-"])

        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake()])
        insertOrderStats(orderStats, timeRange: timeRange)

        // Then
        XCTAssertEqual(conversionStatsTextValues, ["-", "0.0%"])
    }

    // MARK: - Stats text values while selecting a time interval

    func test_orderStatsText_and_revenueStatsText_are_emitted_after_order_stats_updated_with_selected_interval() {
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
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2019-07-09 01:00:00",
                                                               dateEnd: "2019-07-09 01:59:59",
                                                               subtotals: .fake().copy(totalOrders: 1, grossRevenue: 25)),
                                                  .fake().copy(dateStart: "2019-07-09 00:00:00",
                                                               dateEnd: "2019-07-09 00:59:59",
                                                               subtotals: .fake().copy(totalOrders: 2, grossRevenue: 31))
                                                 ])
        insertOrderStats(orderStats, timeRange: timeRange)

        viewModel.selectedIntervalIndex = 1 // Corresponds to the second earliest interval, which is the first interval in `OrderStatsV4`.

        // Then
        XCTAssertEqual(orderStatsTextValues, ["-", "3", "1"])
        XCTAssertEqual(revenueStatsTextValues, ["-", "$62.70", "$25.00"])
        XCTAssertEqual(visitorStatsTextValues, ["-"])
        XCTAssertEqual(conversionStatsTextValues, ["-"])
    }

    func test_visitorStatsText_is_emitted_after_visitor_stats_updated_with_selected_interval() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        observeStatsEmittedValues(viewModel: viewModel)

        XCTAssertEqual(orderStatsTextValues, ["-"])
        XCTAssertEqual(revenueStatsTextValues, ["-"])
        XCTAssertEqual(visitorStatsTextValues, ["-"])
        XCTAssertEqual(conversionStatsTextValues, ["-"])

        // When
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(siteID: siteID, items: [
            .fake().copy(period: "1", visitors: 17),
            .fake().copy(period: "0", visitors: 5)
        ])
        insertSiteVisitStats(siteVisitStats, timeRange: timeRange)

        // Corresponds to the second in intervals sorted by period, which is the first interval in `SiteVisitStats`.
        viewModel.selectedIntervalIndex = 1

        // Then
        XCTAssertEqual(orderStatsTextValues, ["-"])
        XCTAssertEqual(revenueStatsTextValues, ["-"])
        XCTAssertEqual(visitorStatsTextValues, ["-", "22", "17"])
        XCTAssertEqual(conversionStatsTextValues, ["-"])
    }

    func test_conversionStatsText_is_emitted_after_order_and_visitor_stats_updated_with_selected_interval() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        observeStatsEmittedValues(viewModel: viewModel)

        // When
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(siteID: siteID, items: [
            .fake().copy(visitors: 10),
        ])
        insertSiteVisitStats(siteVisitStats, timeRange: timeRange)

        XCTAssertEqual(conversionStatsTextValues, ["-"])

        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 2, grossRevenue: 62.7),
                                      intervals: [.fake().copy(subtotals: .fake().copy(totalOrders: 1, grossRevenue: 25))])
        insertOrderStats(orderStats, timeRange: timeRange)

        viewModel.selectedIntervalIndex = 0

        // Then
        XCTAssertEqual(conversionStatsTextValues, ["-", "20.0%", "10.0%"])
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
        XCTAssertEqual(timeRangeBarViewModels.map { $0.timeRangeText }, ["Monday, Jan 3", "Monday, Jan 3, 1:00 AM"])
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

        XCTAssertEqual(timeRangeBarViewModels.map { $0.timeRangeText }, ["Jan 3 - Jan 5"])

        viewModel.selectedIntervalIndex = 1

        // Then
        XCTAssertEqual(timeRangeBarViewModels.map { $0.timeRangeText }, ["Jan 3 - Jan 5", "Jan 5"])
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

    // MARK: - `reloadChartAnimated`

    func test_reloadChartAnimated_is_emitted_once_after_order_stats_are_updated() {
        // Given
        let timeRange: StatsTimeRangeV4 = .today
        let viewModel = createViewModel(timeRange: timeRange)
        var reloadChartAnimatedValues: [Bool] = []
        viewModel.reloadChartAnimated.sink { isAnimated in
            reloadChartAnimatedValues.append(isAnimated)
        }.store(in: &cancellables)

        XCTAssertEqual(reloadChartAnimatedValues, [])

        // When
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(siteID: siteID, items: [
            .fake().copy(visitors: 10),
        ])
        insertSiteVisitStats(siteVisitStats, timeRange: timeRange)

        // `reloadChartAnimated` is not emitted after visitor stats are updated.
        XCTAssertEqual(reloadChartAnimatedValues, [])

        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: timeRange.intervalGranularity,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2022-01-03 01:00:00",
                                                               dateEnd: "2022-01-03 01:59:59")])
        insertOrderStats(orderStats, timeRange: timeRange)

        // `reloadChartAnimated` is emitted after order stats are updated.
        XCTAssertEqual(reloadChartAnimatedValues, [false])

        viewModel.selectedIntervalIndex = 0

        // `reloadChartAnimated` is not emitted again after visitor stats are updated.
        XCTAssertEqual(reloadChartAnimatedValues, [false])
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
}

private extension StoreStatsPeriodViewModelTests {
    func createViewModel(timeRange: StatsTimeRangeV4) -> StoreStatsPeriodViewModel {
        StoreStatsPeriodViewModel(siteID: siteID,
                                  timeRange: timeRange,
                                  siteTimezone: defaultSiteTimezone,
                                  currencyFormatter: currencyFormatter,
                                  currencyCode: currencyCode,
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
        let storageOrderStats = storage.insertNewObject(ofType: Storage.OrderStatsV4.self)
        storageOrderStats.timeRange = timeRange.rawValue
        storageOrderStats.totals = storage.insertNewObject(ofType: Storage.OrderStatsV4Totals.self)
        storageOrderStats.update(with: readonlyOrderStats)
        readonlyOrderStats.intervals.forEach { readOnlyInterval in
            let newStorageInterval = storage.insertNewObject(ofType: Storage.OrderStatsV4Interval.self)
            newStorageInterval.subtotals = storage.insertNewObject(ofType: Storage.OrderStatsV4Totals.self)
            newStorageInterval.update(with: readOnlyInterval)
            storageOrderStats.addToIntervals(newStorageInterval)
        }
        storage.saveIfNeeded()
    }

    func insertSiteVisitStats(_ readonlySiteVisitStats: Yosemite.SiteVisitStats, timeRange: StatsTimeRangeV4) {
        let storageSiteVisitStats = storage.insertNewObject(ofType: Storage.SiteVisitStats.self)
        storageSiteVisitStats.timeRange = timeRange.rawValue
        storageSiteVisitStats.update(with: readonlySiteVisitStats)
        readonlySiteVisitStats.items?.forEach { readOnlyItem in
            let newStorageItem = storage.insertNewObject(ofType: Storage.SiteVisitStatsItem.self)
            newStorageItem.update(with: readOnlyItem)
            storageSiteVisitStats.addToItems(newStorageItem)
        }
        storage.saveIfNeeded()
    }
}
