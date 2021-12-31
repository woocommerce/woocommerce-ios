import Combine
import Yosemite
import Combine
import Foundation

final class StoreStatsPeriodViewModel {
    // MARK: - Stats data text (public)

    @Published private(set) var orderStatsText: String = Constants.placeholderText
    @Published private(set) var visitorStatsText: String = Constants.placeholderText
    @Published private(set) var conversionStatsText: String = Constants.placeholderText
    @Published private(set) var revenueStatsText: String = Constants.placeholderText
    @Published private(set) var summaryDateUpdatedText: String = ""

    // Set externally from user interactions with the chart.
    @Published var selectedIntervalIndex: Int? = nil

    var timeRangeBarViewModel: AnyPublisher<StatsTimeRangeBarViewModel, Never> {
        timeRangeBarViewModelSubject.eraseToAnyPublisher()
    }

    var reloadChartAnimated: AnyPublisher<Bool, Never> {
        shouldReloadChartAnimated.eraseToAnyPublisher()
    }

    private(set) var orderStatsIntervals: [OrderStatsV4Interval] = []

    // MARK: - Stats data (private)

    @Published private var orderStats: OrderStatsV4?
    @Published private var siteStats: SiteVisitStats?

    private let timeRangeBarViewModelSubject: PassthroughSubject<StatsTimeRangeBarViewModel, Never> = .init()
    private let shouldReloadChartAnimated: PassthroughSubject<Bool, Never> = .init()

    private var lastUpdatedDate: Date? {
        didSet {
            guard let lastUpdatedDate = lastUpdatedDate else {
                return summaryDateUpdatedText = ""
            }
            summaryDateUpdatedText = lastUpdatedDate.relativelyFormattedUpdateString
        }
    }

    // MARK: - Results controllers

    /// SiteVisitStats ResultsController: Loads site visit stats from the Storage Layer
    ///
    private lazy var siteStatsResultsController: ResultsController<StorageSiteVisitStats> = {
        return updateSiteVisitStatsResultsController(currentDate: currentDate)
    }()

    /// OrderStats ResultsController: Loads order stats from the Storage Layer
    ///
    private lazy var orderStatsResultsController: ResultsController<StorageOrderStatsV4> = {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "timeRange ==[c] %@", timeRange.rawValue)
        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()

    // MARK: - Configurations

    let granularity: StatsGranularityV4

    /// Updated when reloading data.
    var siteTimezone: TimeZone = .current

    var currentDate: Date {
        didSet {
            if currentDate != oldValue {
                let currentDateForSiteVisitStats = timeRange.latestDate(currentDate: currentDate, siteTimezone: siteTimezone)
                siteStatsResultsController = updateSiteVisitStatsResultsController(currentDate: currentDateForSiteVisitStats)
                configureSiteStatsResultsController()
            }
        }
    }

    private let timeRange: StatsTimeRangeV4
    private let currencyFormatter: CurrencyFormatter
    private let currencyCode: String

    private var cancellables: Set<AnyCancellable> = []

    init(timeRange: StatsTimeRangeV4, currentDate: Date, currencyFormatter: CurrencyFormatter, currencyCode: String) {
        self.timeRange = timeRange
        self.granularity = timeRange.intervalGranularity // TODO: used?
        self.currentDate = currentDate
        self.currencyFormatter = currencyFormatter
        self.currencyCode = currencyCode

        // Make sure the ResultsControllers are ready to observe changes to the data even before the view loads
        configureResultsControllers()
        observeOrderStats()
        observeSiteVisitData()
        observeConversionData()
    }

    func formattedChartMarkerPeriodString(for item: OrderStatsV4Interval) -> String {
        let chartDateFormatter = timeRange.chartDateFormatter(siteTimezone: siteTimezone)
        return chartDateFormatter.string(from: item.dateStart(timeZone: siteTimezone))
    }
}

// MARK: Observations
//
private extension StoreStatsPeriodViewModel {
    // MARK: - Order stats

    func observeOrderStats() {
        Publishers.CombineLatest($orderStats.eraseToAnyPublisher(), $selectedIntervalIndex.eraseToAnyPublisher())
            .sink { [weak self] orderStats, selectedIntervalIndex in
                guard let self = self else { return }
                let orderStatsIntervals = self.orderStatsIntervals(from: orderStats)
                self.updateTimeRangeBarViewModel(orderStats: orderStats, orderStatsIntervals: orderStatsIntervals, selectedIntervalIndex: selectedIntervalIndex)
                self.updateOrderStatsLabel(orderStats: orderStats, orderStatsIntervals: orderStatsIntervals, selectedIntervalIndex: selectedIntervalIndex)
                self.updateRevenueStatsLabel(orderStats: orderStats, orderStatsIntervals: orderStatsIntervals, selectedIntervalIndex: selectedIntervalIndex)
            }.store(in: &cancellables)
    }

    func updateTimeRangeBarViewModel(orderStats: OrderStatsV4?, orderStatsIntervals: [OrderStatsV4Interval], selectedIntervalIndex: Int?) {
        guard let startDate = orderStatsIntervals.first?.dateStart(timeZone: siteTimezone),
            let endDate = orderStatsIntervals.last?.dateStart(timeZone: siteTimezone) else {
                return
        }
        guard let selectedIndex = selectedIntervalIndex else {
            let viewMoel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                                   endDate: endDate,
                                                                   timeRange: timeRange,
                                                                   timezone: siteTimezone)
            timeRangeBarViewModelSubject.send(viewMoel)
            return
        }
        let date = orderStatsIntervals[selectedIndex].dateStart(timeZone: siteTimezone)
        let viewMoel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                               endDate: endDate,
                                                               selectedDate: date,
                                                               timeRange: timeRange,
                                                               timezone: siteTimezone)
        timeRangeBarViewModelSubject.send(viewMoel)
    }

    func updateOrderStatsLabel(orderStats: OrderStatsV4?, orderStatsIntervals: [OrderStatsV4Interval], selectedIntervalIndex: Int?) {
        if let count = orderCount(at: selectedIntervalIndex, orderStats: orderStats, orderStatsIntervals: orderStatsIntervals) {
            orderStatsText = Double(count).humanReadableString()
        } else {
            orderStatsText = Constants.placeholderText
        }
    }

    func updateRevenueStatsLabel(orderStats: OrderStatsV4?, orderStatsIntervals: [OrderStatsV4Interval], selectedIntervalIndex: Int?) {
        if let revenue = revenue(at: selectedIntervalIndex, orderStats: orderStats, orderStatsIntervals: orderStatsIntervals) {
            revenueStatsText = currencyFormatter.formatHumanReadableAmount(String("\(revenue)"), with: currencyCode) ?? String()
        } else {
            revenueStatsText = Constants.placeholderText
        }
    }

    // MARK: - Site visit stats

    func observeSiteVisitData() {
        Publishers.CombineLatest($siteStats.eraseToAnyPublisher(), $selectedIntervalIndex.eraseToAnyPublisher())
            .sink { [weak self] siteStats, selectedIntervalIndex in
                guard let self = self else { return }
                self.updateVisitorStatsLabel(siteStats: siteStats, selectedIntervalIndex: selectedIntervalIndex)
            }.store(in: &cancellables)
    }

    func updateVisitorStatsLabel(siteStats: SiteVisitStats?, selectedIntervalIndex: Int?) {
        if let visitorCount = visitorCount(at: selectedIntervalIndex, siteStats: siteStats) {
            visitorStatsText = Double(visitorCount).humanReadableString()
        } else {
            visitorStatsText = Constants.placeholderText
        }
    }

    // MARK: - Conversion stats

    func observeConversionData() {
        Publishers.CombineLatest3($orderStats.eraseToAnyPublisher(), $siteStats.eraseToAnyPublisher(), $selectedIntervalIndex.eraseToAnyPublisher())
            .sink { [weak self] orderStats, siteStats, selectedIntervalIndex in
                guard let self = self else { return }
                self.updateConversionStatsLabel(orderStats: orderStats, siteStats: siteStats, selectedIntervalIndex: selectedIntervalIndex)
            }.store(in: &cancellables)
    }

    func updateConversionStatsLabel(orderStats: OrderStatsV4?, siteStats: SiteVisitStats?, selectedIntervalIndex: Int?) {
        let visitors = visitorCount(at: selectedIntervalIndex, siteStats: siteStats)
        let orders = orderCount(at: selectedIntervalIndex, orderStats: orderStats, orderStatsIntervals: orderStatsIntervals(from: orderStats))
        if let visitors = visitors, let orders = orders, visitors > 0 {
            // Maximum conversion rate is 100%.
            let conversionRate = min(orders/visitors, 1)
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .percent
            numberFormatter.minimumFractionDigits = 1
            conversionStatsText = numberFormatter.string(from: conversionRate as NSNumber) ?? Constants.placeholderText
        } else {
            conversionStatsText = Constants.placeholderText
        }
    }
}

// MARK: - Private data helpers
//
private extension StoreStatsPeriodViewModel {
    func visitorCount(at selectedIndex: Int?, siteStats: SiteVisitStats?) -> Double? {
        let siteStatsItems = siteStats?.items?.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.period < rhs.period
        }) ?? []
        if let selectedIndex = selectedIndex {
            guard selectedIndex < siteStatsItems.count else {
                return nil
            }
            return Double(siteStatsItems[selectedIndex].visitors)
        } else if let siteStats = siteStats {
            return Double(siteStats.totalVisitors)
        } else {
            return nil
        }
    }

    func orderCount(at selectedIndex: Int?, orderStats: OrderStatsV4?, orderStatsIntervals: [OrderStatsV4Interval]) -> Double? {
        if let selectedIndex = selectedIndex {
            let orderStats = orderStatsIntervals[selectedIndex]
            return Double(orderStats.subtotals.totalOrders)
        } else if let orderStats = orderStats {
            return Double(orderStats.totals.totalOrders)
        } else {
            return nil
        }
    }

    func revenue(at selectedIndex: Int?, orderStats: OrderStatsV4?, orderStatsIntervals: [OrderStatsV4Interval]) -> Decimal? {
        if let selectedIndex = selectedIndex, selectedIndex < orderStatsIntervals.count {
            let orderStats = orderStatsIntervals[selectedIndex]
            return orderStats.subtotals.grossRevenue
        } else if let orderStats = orderStats {
            return orderStats.totals.grossRevenue
        } else {
            return nil
        }
    }

    func orderStatsIntervals(from orderStats: OrderStatsV4?) -> [OrderStatsV4Interval] {
        return orderStats?.intervals.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.dateStart(timeZone: self.siteTimezone) < rhs.dateStart(timeZone: self.siteTimezone)
        }) ?? []
    }
}

// MARK: - Results controller
//
private extension StoreStatsPeriodViewModel {
    func configureResultsControllers() {
        configureSiteStatsResultsController()

        // Order Stats
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

    func updateSiteVisitStatsResultsController(currentDate: Date) -> ResultsController<StorageSiteVisitStats> {
        let storageManager = ServiceLocator.storageManager
        let dateFormatter = DateFormatter.Stats.statsDayFormatter
        dateFormatter.timeZone = siteTimezone
        let predicate = NSPredicate(format: "granularity ==[c] %@ AND timeRange == %@",
                                    timeRange.siteVisitStatsGranularity.rawValue,
                                    timeRange.rawValue)
        let descriptor = NSSortDescriptor(keyPath: \StorageSiteVisitStats.date, ascending: false)
        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }
}

// MARK: - Private Helpers
//
private extension StoreStatsPeriodViewModel {
    func updateSiteVisitDataIfNeeded() {
        siteStats = siteStatsResultsController.fetchedObjects.first

        if siteStats != nil {
            lastUpdatedDate = Date()
        } else {
            lastUpdatedDate = nil
        }
    }

    func updateOrderDataIfNeeded() {
        orderStats = orderStatsResultsController.fetchedObjects.first
        orderStatsIntervals = orderStats?.intervals.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.dateStart(timeZone: siteTimezone) < rhs.dateStart(timeZone: siteTimezone)
        }) ?? []

        // Don't animate the chart here - this helps avoid a "double animation" effect if a
        // small number of values change (the chart WILL be updated correctly however)
        shouldReloadChartAnimated.send(false)

        if orderStats?.intervals.isEmpty == false {
            lastUpdatedDate = Date()
        } else {
            lastUpdatedDate = nil
        }
    }
}

private extension StoreStatsPeriodViewModel {
    enum Constants {
        static let placeholderText                      = "-"
    }
}
