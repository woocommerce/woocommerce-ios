import Combine
import protocol Storage.StorageManagerType
import Yosemite
import Foundation
import WooFoundation

/// Provides data and observables for UI in `StoreStatsV4PeriodViewController`.
final class StoreStatsPeriodViewModel {
    // MARK: - Public data & observables

    /// Used for chart updates.
    private(set) lazy var orderStatsIntervals: AnyPublisher<[OrderStatsV4Interval], Never> =
    $orderStatsData.map { $0.intervals }.eraseToAnyPublisher()

    /// Updated externally from user interactions with the chart.
    @Published var selectedIntervalIndex: Int? = nil

    /// Updated externally from visitor stats availability.
    @Published var siteVisitStatsMode: SiteVisitStatsMode = .default

    /// Emits order stats text values based on order stats and selected time interval.
    private(set) lazy var orderStatsText: AnyPublisher<String, Never> =
    Publishers.CombineLatest($orderStatsData.eraseToAnyPublisher(), $selectedIntervalIndex.eraseToAnyPublisher())
        .compactMap { [weak self] orderStatsData, selectedIntervalIndex in
            StatsDataTextFormatter.createOrderCountText(orderStats: orderStatsData.stats, selectedIntervalIndex: selectedIntervalIndex)
        }
        .removeDuplicates()
        .eraseToAnyPublisher()

    /// Emits revenue stats text values based on order stats, selected time interval, and currency code.
    private(set) lazy var revenueStatsText: AnyPublisher<String, Never> = $orderStatsData.combineLatest($selectedIntervalIndex, currencySettings.$currencyCode)
        .compactMap { [weak self] orderStatsData, selectedIntervalIndex, currencyCode in
            guard let self else { return "-" }
            return StatsDataTextFormatter.createTotalRevenueText(orderStats: orderStatsData.stats,
                                                                 selectedIntervalIndex: selectedIntervalIndex,
                                                                 currencyFormatter: self.currencyFormatter,
                                                                 currencyCode: currencyCode.rawValue)
        }
        .removeDuplicates()
        .eraseToAnyPublisher()

    /// Emits visitor stats text values based on site visit stats and selected time interval.
    private(set) lazy var visitorStatsText: AnyPublisher<String, Never> =
    Publishers.CombineLatest3($siteStats.eraseToAnyPublisher(), $selectedIntervalIndex.eraseToAnyPublisher(), $summaryStats.eraseToAnyPublisher())
        .compactMap { siteStats, selectedIntervalIndex, summaryStats in
            if let selectedIntervalIndex {
                return StatsDataTextFormatter.createVisitorCountText(siteStats: siteStats, selectedIntervalIndex: selectedIntervalIndex)
            } else {
                return StatsDataTextFormatter.createVisitorCountText(siteStats: summaryStats)
            }
        }
        .removeDuplicates()
        .eraseToAnyPublisher()

    /// Emits conversion stats text values based on order stats, site visit stats, and selected time interval.
    private(set) lazy var conversionStatsText: AnyPublisher<String, Never> =
    Publishers.CombineLatest4($orderStatsData.eraseToAnyPublisher(),
                              $siteStats.eraseToAnyPublisher(),
                              $selectedIntervalIndex.eraseToAnyPublisher(),
                              $summaryStats.eraseToAnyPublisher())
        .compactMap { orderStatsData, siteStats, selectedIntervalIndex, summaryStats in
            if let selectedIntervalIndex {
                return StatsDataTextFormatter.createConversionRateText(orderStats: orderStatsData.stats,
                                                                       siteStats: siteStats,
                                                                       selectedIntervalIndex: selectedIntervalIndex)
            } else {
                return StatsDataTextFormatter.createConversionRateText(orderStats: orderStatsData.stats, siteStats: summaryStats)
            }
        }
        .removeDuplicates()
        .eraseToAnyPublisher()

    /// Emits view models for time range bar that shows the time range for the selected time interval.
    private(set) lazy var timeRangeBarViewModel: AnyPublisher<StatsTimeRangeBarViewModel, Never> =
    Publishers.CombineLatest($orderStatsData.eraseToAnyPublisher(), $selectedIntervalIndex.eraseToAnyPublisher())
        .compactMap { [weak self] orderStatsData, selectedIntervalIndex in
            return self?.createTimeRangeBarViewModel(orderStatsData: orderStatsData, selectedIntervalIndex: selectedIntervalIndex)
        }
        .eraseToAnyPublisher()

    /// Emits the view state for visitor stats based on the visitor stats mode and the selected time interval.
    private(set) lazy var visitorStatsViewState: AnyPublisher<StoreStatsDataOrRedactedView.State, Never> =
    Publishers.CombineLatest($siteVisitStatsMode.eraseToAnyPublisher(), $selectedIntervalIndex.eraseToAnyPublisher())
        .compactMap { [weak self] siteVisitStatsMode, selectedIntervalIndex in
            return self?.visitorStatsViewState(siteVisitStatsMode: siteVisitStatsMode, selectedIntervalIndex: selectedIntervalIndex)
        }
        .removeDuplicates()
        .eraseToAnyPublisher()

    /// Emits the view state for conversion stats based on the visitor stats view state.
    private(set) lazy var conversionStatsViewState: AnyPublisher<StoreStatsDataOrRedactedView.State, Never> =
    visitorStatsViewState
        .compactMap { [weak self] visitorStatsViewState in
            return self?.conversionStatsViewState(visitorStatsViewState: visitorStatsViewState)
        }
        .removeDuplicates()
        .eraseToAnyPublisher()

    /// Emits the maximum value for the y-axis in the chart based on the order stats data.
    private(set) lazy var yAxisMaximum: AnyPublisher<Double, Never> =
    $orderStatsData.eraseToAnyPublisher()
        .compactMap { [weak self] orderStatsData in
            return self?.createYAxisMaximum(orderStatsData: orderStatsData)
        }
        .removeDuplicates()
        .eraseToAnyPublisher()

    /// Emits the minimum value for the y-axis in the chart based on the order stats data.
    private(set) lazy var yAxisMinimum: AnyPublisher<Double, Never> =
    $orderStatsData.eraseToAnyPublisher()
        .compactMap { [weak self] orderStatsData in
            return self?.createYAxisMinimum(orderStatsData: orderStatsData)
        }
        .removeDuplicates()
        .eraseToAnyPublisher()

    // MARK: - Private data

    @Published private var siteStats: SiteVisitStats?
    @Published private var summaryStats: SiteSummaryStats?

    typealias OrderStatsData = (stats: OrderStatsV4?, intervals: [OrderStatsV4Interval])
    @Published private var orderStatsData: OrderStatsData = (nil, [])

    // MARK: - Results controllers

    /// SiteVisitStats ResultsController: Loads site visit stats from the Storage Layer
    private lazy var siteStatsResultsController: ResultsController<StorageSiteVisitStats> = {
        let predicate = NSPredicate(format: "siteID = %ld AND granularity ==[c] %@ AND timeRange == %@",
                                    siteID,
                                    timeRange.siteVisitStatsGranularity.rawValue,
                                    timeRange.rawValue)
        let descriptor = NSSortDescriptor(keyPath: \StorageSiteVisitStats.date, ascending: false)
        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// OrderStats ResultsController: Loads order stats from the Storage Layer
    private lazy var orderStatsResultsController: ResultsController<StorageOrderStatsV4> = {
        let predicate = NSPredicate(format: "siteID = %ld AND timeRange ==[c] %@", siteID, timeRange.rawValue)
        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()

    /// SiteSummaryStats ResultsController: Loads site summary stats from the Storage Layer
    private lazy var summaryStatsResultsController: ResultsController<StorageSiteSummaryStats> = {
        let formattedDateString: String = {
            let date = timeRange.latestDate(currentDate: currentDate, siteTimezone: siteTimezone)
            return StatsStoreV4.buildDateString(from: date, with: .day)
        }()
        let predicate = NSPredicate(format: "siteID = %ld AND period == %@ AND date == %@",
                                    siteID,
                                    timeRange.summaryStatsGranularity.rawValue,
                                    formattedDateString)
        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()

    // MARK: - Configurations

    /// Updated externally when reloading data.
    var siteTimezone: TimeZone

    private let siteID: Int64
    private let timeRange: StatsTimeRangeV4
    private let currentDate: Date
    private let currencyFormatter: CurrencyFormatter
    private let storageManager: StorageManagerType
    private let currencySettings: CurrencySettings

    private var cancellables: Set<AnyCancellable> = []

    init(siteID: Int64,
         timeRange: StatsTimeRangeV4,
         siteTimezone: TimeZone,
         currentDate: Date,
         currencyFormatter: CurrencyFormatter,
         currencySettings: CurrencySettings,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.timeRange = timeRange
        self.siteTimezone = siteTimezone
        self.currentDate = currentDate
        self.currencyFormatter = currencyFormatter
        self.currencySettings = currencySettings
        self.storageManager = storageManager

        // Make sure the ResultsControllers are ready to observe changes to the data even before the view loads
        configureResultsControllers()
    }
}

// MARK: Private helpers for public data calculation
//
private extension StoreStatsPeriodViewModel {
    func createTimeRangeBarViewModel(orderStatsData: OrderStatsData, selectedIntervalIndex: Int?) -> StatsTimeRangeBarViewModel? {
        let orderStatsIntervals = orderStatsData.intervals
        guard let startDate = orderStatsIntervals.first?.dateStart(timeZone: self.siteTimezone),
              let endDate = orderStatsIntervals.last?.dateStart(timeZone: self.siteTimezone) else {
                  return nil
              }
        guard let selectedIndex = selectedIntervalIndex else {
            return StatsTimeRangeBarViewModel(startDate: startDate,
                                              endDate: endDate,
                                              timeRange: timeRange,
                                              timezone: siteTimezone)
        }
        let date = orderStatsIntervals[selectedIndex].dateStart(timeZone: siteTimezone)
        return StatsTimeRangeBarViewModel(startDate: startDate,
                                          endDate: endDate,
                                          selectedDate: date,
                                          timeRange: timeRange,
                                          timezone: siteTimezone)
    }

    func visitorStatsViewState(siteVisitStatsMode: SiteVisitStatsMode, selectedIntervalIndex: Int?) -> StoreStatsDataOrRedactedView.State {
        switch siteVisitStatsMode {
        case .default:
            return timeRange == .today && selectedIntervalIndex != nil ? .redacted: .data
        case .redactedDueToJetpack:
            return .redactedDueToJetpack
        case .hidden:
            return .redacted
        }
    }

    func conversionStatsViewState(visitorStatsViewState: StoreStatsDataOrRedactedView.State) -> StoreStatsDataOrRedactedView.State {
        switch visitorStatsViewState {
        case .data:
            return .data
        case .redactedDueToJetpack:
            return .redacted
        case .redacted:
            return .redacted
        }
    }

    func createYAxisMaximum(orderStatsData: OrderStatsData) -> Double {
        let revenueItems = orderStatsData.intervals.map({ ($0.revenueValue as NSDecimalNumber).doubleValue })
        guard revenueItems.contains(where: { $0 != 0 }) else {
            return Constants.yAxisMaximumValueWithoutRevenue
        }
        let hasNegativeRevenueOnly = revenueItems.contains(where: { $0 > 0 }) == false
        guard hasNegativeRevenueOnly == false else {
            return 0
        }

        let max = revenueItems.max() ?? 0
        return max.roundedToTheNextSamePowerOfTen(shouldRoundUp: true)
    }

    func createYAxisMinimum(orderStatsData: OrderStatsData) -> Double {
        let revenueItems = orderStatsData.intervals.map({ ($0.revenueValue as NSDecimalNumber).doubleValue })
        guard revenueItems.contains(where: { $0 != 0 }) else {
            return Constants.yAxisMinimumValueWithoutRevenue
        }

        let min = revenueItems.min() ?? 0
        if min < 0 {
            return min.roundedToTheNextSamePowerOfTen(shouldRoundUp: false)
        } else {
            return 0
        }
    }
}

// MARK: - Results controller
//
private extension StoreStatsPeriodViewModel {
    func configureResultsControllers() {
        configureSiteStatsResultsController()
        configureOrderStatsResultsController()
        configureSummaryStatsResultsController()
    }

    func configureOrderStatsResultsController() {
        orderStatsResultsController.onDidChangeContent = { [weak self] in
            self?.updateOrderDataIfNeeded()
        }
        orderStatsResultsController.onDidResetContent = { [weak self] in
            self?.updateOrderDataIfNeeded()
        }
        try? orderStatsResultsController.performFetch()
    }

    func configureSiteStatsResultsController() {
        siteStatsResultsController.onDidChangeContent = { [weak self] in
            self?.updateSiteVisitDataIfNeeded()
        }
        siteStatsResultsController.onDidResetContent = { [weak self] in
            self?.updateSiteVisitDataIfNeeded()
        }
        try? siteStatsResultsController.performFetch()
    }

    func configureSummaryStatsResultsController() {
        summaryStatsResultsController.onDidChangeContent = { [weak self] in
            self?.updateSiteSummaryDataIfNeeded()
        }
        summaryStatsResultsController.onDidResetContent = { [weak self] in
            self?.updateSiteSummaryDataIfNeeded()
        }
        try? summaryStatsResultsController.performFetch()
    }
}

// MARK: - Private Helpers
//
private extension StoreStatsPeriodViewModel {
    func updateSiteVisitDataIfNeeded() {
        siteStats = siteStatsResultsController.fetchedObjects.first
    }

    func updateSiteSummaryDataIfNeeded() {
        summaryStats = summaryStatsResultsController.fetchedObjects.first
    }

    func updateOrderDataIfNeeded() {
        let orderStats = orderStatsResultsController.fetchedObjects.first
        let intervals = StatsIntervalDataParser.sortOrderStatsIntervals(from: orderStats)
        orderStatsData = (stats: orderStats, intervals: intervals)
    }
}

private extension StoreStatsPeriodViewModel {
    enum Constants {
        static let yAxisMaximumValueWithoutRevenue: Double = 1
        static let yAxisMinimumValueWithoutRevenue: Double = -1
    }
}
