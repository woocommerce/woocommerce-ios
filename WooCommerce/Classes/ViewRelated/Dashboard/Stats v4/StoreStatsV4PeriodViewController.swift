import Charts
import UIKit
import Yosemite

/// Shows the store stats with v4 API for a time range.
///
class StoreStatsV4PeriodViewController: UIViewController {

    // MARK: - Public Properties

    let granularity: StatsGranularityV4

    var shouldShowSiteVisitStats: Bool = true {
        didSet {
            updateSiteVisitStatsVisibility(shouldShowSiteVisitStats: shouldShowSiteVisitStats)
        }
    }

    var currentDate: Date {
        didSet {
            if currentDate != oldValue {
                let currentDateForSiteVisitStats = timeRange.latestDate(currentDate: currentDate, siteTimezone: siteTimezone)
                siteStatsResultsController = updateSiteVisitStatsResultsController(currentDate: currentDateForSiteVisitStats)
                configureSiteStatsResultsController()
            }
        }
    }

    /// Updated when reloading data.
    var siteTimezone: TimeZone = .current

    // MARK: - Private Properties
    private let timeRange: StatsTimeRangeV4
    private var orderStatsIntervals: [OrderStatsV4Interval] = [] {
        didSet {
            let helper = StoreStatsV4ChartAxisHelper()
            let intervalDates = orderStatsIntervals.map({ $0.dateStart() })
            orderStatsIntervalLabels = helper.generateLabelText(for: intervalDates,
                                                                timeRange: timeRange,
                                                                siteTimezone: siteTimezone)
        }
    }
    private var orderStatsIntervalLabels: [String] = []

    private var orderStats: OrderStatsV4? {
        return orderStatsResultsController.fetchedObjects.first
    }
    private var siteStats: SiteVisitStats? {
        return siteStatsResultsController.fetchedObjects.first
    }
    private var siteStatsItems: [SiteVisitStatsItem] = []

    // MARK: - Subviews

    @IBOutlet private weak var containerStackView: UIStackView!
    @IBOutlet private weak var visitorsStackView: UIStackView!
    @IBOutlet private weak var visitorsTitle: UILabel!
    @IBOutlet private weak var visitorsData: UILabel!
    @IBOutlet private weak var ordersTitle: UILabel!
    @IBOutlet private weak var ordersData: UILabel!
    @IBOutlet private weak var revenueTitle: UILabel!
    @IBOutlet private weak var revenueData: UILabel!
    @IBOutlet private weak var barChartView: BarChartView!
    @IBOutlet private weak var lastUpdated: UILabel!
    @IBOutlet private weak var borderView: UIView!
    @IBOutlet private weak var yAxisAccessibilityView: UIView!
    @IBOutlet private weak var xAxisAccessibilityView: UIView!
    @IBOutlet private weak var chartAccessibilityView: UIView!
    @IBOutlet private weak var noRevenueView: UIView!
    @IBOutlet private weak var noRevenueLabel: UILabel!
    @IBOutlet private weak var timeRangeBarView: StatsTimeRangeBarView!
    @IBOutlet private weak var timeRangeBarBottomBorderView: UIView!

    private var lastUpdatedDate: Date?
    private var yAxisMinimum: String = Constants.chartYAxisMinimum.humanReadableString()
    private var yAxisMaximum: String = ""
    private var isInitialLoad: Bool = true  // Used in trackChangedTabIfNeeded()

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

    /// Placeholder: Mockup Charts View
    ///
    private lazy var placeholderChartsView: ChartPlaceholderView = ChartPlaceholderView.instantiateFromNib()


    // MARK: - Computed Properties

    private var currencySymbol: String {
        let code = CurrencySettings.shared.currencyCode
        return CurrencySettings.shared.symbol(from: code)
    }

    private var summaryDateUpdated: String {
        guard let lastUpdatedDate = lastUpdatedDate else {
            return ""
        }
        return lastUpdatedDate.relativelyFormattedUpdateString
    }

    private var xAxisMinimum: String {
        guard let item = orderStatsIntervals.first else {
            return ""
        }
        return formattedAxisPeriodString(for: item)
    }

    private var xAxisMaximum: String {
        guard let item = orderStatsIntervals.last else {
            return ""
        }
        return formattedAxisPeriodString(for: item)
    }

    // MARK: - Initialization

    /// Designated Initializer
    ///
    init(timeRange: StatsTimeRangeV4, currentDate: Date) {
        self.timeRange = timeRange
        self.granularity = timeRange.intervalGranularity
        self.currentDate = currentDate
        super.init(nibName: type(of: self).nibName, bundle: nil)

        // Make sure the ResultsControllers are ready to observe changes to the data even before the view loads
        self.configureResultsControllers()
    }

    /// NSCoder Conformance
    ///
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureBarChart()
        configureNoRevenueView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadAllFields()
        trackChangedTabIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        barChartView?.clear()
    }
}

// MARK: - Public Interface
//
extension StoreStatsV4PeriodViewController {
    func clearAllFields() {
        barChartView?.clear()
        reloadAllFields(animateChart: false)
    }
}

// MARK: - Ghosts API

extension StoreStatsV4PeriodViewController {

    /// Indicates if the receiver has Remote Stats, or not.
    ///
    var shouldDisplayGhostContent: Bool {
        return orderStatsIntervals.isEmpty
    }

    /// Displays the Placeholder Period Graph + Starts the Animation.
    /// Why is this public? Because the actual Sync OP is handled by StoreStatsViewController. We coordinate multiple
    /// placeholder animations from that spot!
    ///
    func displayGhostContent() {
        ensurePlaceholderIsVisible()
        placeholderChartsView.startGhostAnimation(style: .wooDefaultGhostStyle)
    }

    /// Removes the Placeholder Content.
    /// Why is this public? Because the actual Sync OP is handled by StoreStatsViewController. We coordinate multiple
    /// placeholder animations from that spot!
    ///
    func removeGhostContent() {
        placeholderChartsView.stopGhostAnimation()
        placeholderChartsView.removeFromSuperview()
    }

    /// Ensures the Placeholder Charts UI is onscreen.
    ///
    private func ensurePlaceholderIsVisible() {
        guard placeholderChartsView.superview == nil else {
            return
        }

        placeholderChartsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderChartsView)
        view.pinSubviewToAllEdges(placeholderChartsView)
    }

}

// MARK: - Configuration
//
private extension StoreStatsV4PeriodViewController {

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

    func configureView() {
        view.backgroundColor = .listForeground
        containerStackView.backgroundColor = .listForeground
        timeRangeBarView.backgroundColor = .listForeground
        visitorsStackView.backgroundColor = .listForeground
        borderView.backgroundColor = .listSmallIcon

        // Time range bar bottom border view
        timeRangeBarBottomBorderView.backgroundColor = .listForeground

        // Titles
        visitorsTitle.text = NSLocalizedString("Visitors", comment: "Visitors stat label on dashboard - should be plural.")
        visitorsTitle.applyFootnoteStyle()
        ordersTitle.text = NSLocalizedString("Orders", comment: "Orders stat label on dashboard - should be plural.")
        ordersTitle.applyFootnoteStyle()
        revenueTitle.text = NSLocalizedString("Revenue", comment: "Revenue stat label on dashboard.")
        revenueTitle.applyFootnoteStyle()

        // Data
        visitorsData.applyTitleStyle()
        ordersData.applyTitleStyle()
        revenueData.applyTitleStyle()

        // Footer
        lastUpdated.font = UIFont.footnote
        lastUpdated.textColor = .textSubtle
        lastUpdated.backgroundColor = .listForeground

        // Visibility
        updateSiteVisitStatsVisibility(shouldShowSiteVisitStats: shouldShowSiteVisitStats)

        // Accessibility elements
        xAxisAccessibilityView.isAccessibilityElement = true
        xAxisAccessibilityView.accessibilityTraits = .staticText
        xAxisAccessibilityView.accessibilityLabel = NSLocalizedString("Store revenue chart: X Axis",
                                                                      comment: "VoiceOver accessibility label for the store revenue chart's X-axis.")
        yAxisAccessibilityView.isAccessibilityElement = true
        yAxisAccessibilityView.accessibilityTraits = .staticText
        yAxisAccessibilityView.accessibilityLabel = NSLocalizedString("Store revenue chart: Y Axis",
                                                                      comment: "VoiceOver accessibility label for the store revenue chart's Y-axis.")
        chartAccessibilityView.isAccessibilityElement = true
        chartAccessibilityView.accessibilityTraits = .image
        chartAccessibilityView.accessibilityLabel = NSLocalizedString("Store revenue chart",
                                                                      comment: "VoiceOver accessibility label for the store revenue chart.")
        chartAccessibilityView.accessibilityLabel = String.localizedStringWithFormat(
            NSLocalizedString("Store revenue chart %@",
                              comment: "VoiceOver accessibility label for the store revenue chart. It reads: Store revenue chart {chart granularity}."),
            timeRange.tabTitle
        )
    }

    func configureNoRevenueView() {
        noRevenueView.isHidden = true
        noRevenueView.backgroundColor = .listForeground
        noRevenueLabel.text = NSLocalizedString("No revenue this period",
                                                comment: "Text displayed when no order data are available for the selected time range.")
        noRevenueLabel.font = StyleManager.subheadlineFont
        noRevenueLabel.textColor = .text
    }

    func configureBarChart() {
        barChartView.chartDescription?.enabled = false
        barChartView.dragEnabled = true
        barChartView.setScaleEnabled(false)
        barChartView.pinchZoomEnabled = false
        barChartView.rightAxis.enabled = false
        barChartView.legend.enabled = false
        barChartView.drawValueAboveBarEnabled = true
        barChartView.noDataText = NSLocalizedString("No data available", comment: "Text displayed when no data is available for revenue chart.")
        barChartView.noDataFont = StyleManager.chartLabelFont
        barChartView.noDataTextColor = .textSubtle
        barChartView.extraRightOffset = Constants.chartExtraRightOffset
        barChartView.extraTopOffset = Constants.chartExtraTopOffset
        barChartView.delegate = self

        let xAxis = barChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = StyleManager.chartLabelFont
        xAxis.labelTextColor = .textSubtle
        xAxis.axisLineColor = .listSmallIcon
        xAxis.gridColor = .listSmallIcon
        xAxis.drawLabelsEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.granularity = Constants.chartXAxisGranularity
        xAxis.granularityEnabled = true
        xAxis.valueFormatter = self
        updateChartXAxisLabelCount(xAxis: xAxis, timeRange: timeRange)

        let yAxis = barChartView.leftAxis
        yAxis.labelFont = StyleManager.chartLabelFont
        yAxis.labelTextColor = .textSubtle
        yAxis.axisLineColor = .listSmallIcon
        yAxis.gridColor = .listSmallIcon
        yAxis.zeroLineColor = .listSmallIcon
        yAxis.drawLabelsEnabled = true
        yAxis.drawGridLinesEnabled = true
        yAxis.drawAxisLineEnabled = false
        yAxis.drawZeroLineEnabled = true
        yAxis.axisMinimum = Constants.chartYAxisMinimum
        yAxis.valueFormatter = self
        yAxis.setLabelCount(3, force: true)
    }
}

// MARK: - Internal Updates
private extension StoreStatsV4PeriodViewController {
    func updateSiteVisitStatsResultsController(currentDate: Date) -> ResultsController<StorageSiteVisitStats> {
        let storageManager = ServiceLocator.storageManager
        let dateFormatter = DateFormatter.Stats.statsDayFormatter
        dateFormatter.timeZone = siteTimezone
        let predicate = NSPredicate(format: "granularity ==[c] %@ AND date == %@",
                                    timeRange.siteVisitStatsGranularity.rawValue,
                                    dateFormatter.string(from: currentDate))
        let descriptor = NSSortDescriptor(keyPath: \StorageSiteVisitStats.date, ascending: false)
        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }

    func updateChartXAxisLabelCount(xAxis: XAxis, timeRange: StatsTimeRangeV4) {
        let helper = StoreStatsV4ChartAxisHelper()
        let labelCount = helper.labelCount(timeRange: timeRange)
        xAxis.setLabelCount(labelCount, force: false)
    }

    func updateUI(hasRevenue: Bool) {
        noRevenueView.isHidden = hasRevenue
        updateBarChartAxisUI(hasRevenue: hasRevenue)
    }

    func updateBarChartAxisUI(hasRevenue: Bool) {
        let xAxis = barChartView.xAxis
        xAxis.labelTextColor = .textSubtle

        let yAxis = barChartView.leftAxis
        yAxis.labelTextColor = .textSubtle
    }
}

// MARK: - UI Updates
//
extension StoreStatsV4PeriodViewController {
    func updateSiteVisitStatsVisibility(shouldShowSiteVisitStats: Bool) {
        visitorsStackView?.isHidden = !shouldShowSiteVisitStats
    }
}

// MARK: - ChartViewDelegate Conformance (Charts)
//
extension StoreStatsV4PeriodViewController: ChartViewDelegate {
    func chartViewDidEndPanning(_ chartView: ChartViewBase) {
        updateUI(selectedBarIndex: nil)
    }

    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        updateUI(selectedBarIndex: nil)
    }

    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let selectedIndex = Int(entry.x)
        updateUI(selectedBarIndex: selectedIndex)
    }
}

private extension StoreStatsV4PeriodViewController {
    /// Updates all stats and time range bar text based on the selected bar index.
    ///
    /// - Parameter selectedIndex: the index of interval data for the bar chart. Nil if no bar is selected.
    func updateUI(selectedBarIndex selectedIndex: Int?) {
        updateSiteVisitStats(selectedIndex: selectedIndex)
        updateOrderStats(selectedIndex: selectedIndex)
        updateTimeRangeBar(selectedIndex: selectedIndex)
    }

    /// Updates order stats based on the selected bar index.
    ///
    /// - Parameter selectedIndex: the index of interval data for the bar chart. Nil if no bar is selected.
    func updateOrderStats(selectedIndex: Int?) {
        guard let selectedIndex = selectedIndex else {
            reloadOrderFields()
            return
        }
        guard ordersData != nil, revenueData != nil else {
            return
        }
        var totalOrdersText = Constants.placeholderText
        var totalRevenueText = Constants.placeholderText
        let currencyCode = CurrencySettings.shared.symbol(from: CurrencySettings.shared.currencyCode)
        if selectedIndex < orderStatsIntervals.count {
            let orderStats = orderStatsIntervals[selectedIndex]
            totalOrdersText = Double(orderStats.subtotals.totalOrders).humanReadableString()
            totalRevenueText = CurrencyFormatter().formatHumanReadableAmount(String("\(orderStats.subtotals.grossRevenue)"), with: currencyCode) ?? String()
        }
        ordersData.text = totalOrdersText
        revenueData.text = totalRevenueText
    }

    /// Updates stats based on the selected bar index.
    ///
    /// - Parameter selectedIndex: the index of interval data for the bar chart. Nil if no bar is selected.
    func updateSiteVisitStats(selectedIndex: Int?) {
        guard shouldShowSiteVisitStats else {
            return
        }
        guard let selectedIndex = selectedIndex else {
            updateSiteVisitStatsVisibility(shouldShowSiteVisitStats: shouldShowSiteVisitStats)
            reloadSiteFields()
            return
        }
        // Hides site visit stats for "today".
        guard timeRange != .today else {
            updateSiteVisitStatsVisibility(shouldShowSiteVisitStats: false)
            return
        }
        updateSiteVisitStatsVisibility(shouldShowSiteVisitStats: true)
        guard visitorsData != nil else {
            return
        }

        var visitorsText = Constants.placeholderText
        if selectedIndex < siteStatsItems.count {
            let siteStatsItem = siteStatsItems[selectedIndex]
            visitorsText = Double(siteStatsItem.visitors).humanReadableString()
        }
        visitorsData.text = visitorsText
    }

    /// Updates date bar based on the selected bar index.
    ///
    /// - Parameter selectedIndex: the index of interval data for the bar chart. Nil if no bar is selected.
    func updateTimeRangeBar(selectedIndex: Int?) {
        guard let startDate = orderStatsIntervals.first?.dateStart(),
            let endDate = orderStatsIntervals.last?.dateStart() else {
                return
        }
        guard let selectedIndex = selectedIndex else {
            let timeRangeBarViewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                                   endDate: endDate,
                                                                   timeRange: timeRange,
                                                                   timezone: siteTimezone)
            timeRangeBarView.updateUI(viewModel: timeRangeBarViewModel)
            return
        }
        let date = orderStatsIntervals[selectedIndex].dateStart()
        let timeRangeBarViewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                               endDate: endDate,
                                                               selectedDate: date,
                                                               timeRange: timeRange,
                                                               timezone: siteTimezone)
        timeRangeBarView.updateUI(viewModel: timeRangeBarViewModel)
    }
}

// MARK: - IAxisValueFormatter Conformance (Charts)
//
extension StoreStatsV4PeriodViewController: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        guard let axis = axis else {
            return ""
        }

        if axis is XAxis {
            return orderStatsIntervalLabels[Int(value)]
        } else {
            if value == 0.0 {
                // Do not show the "0" label on the Y axis
                return ""
            } else {
                yAxisMaximum = value.humanReadableString()
                return CurrencyFormatter().formatCurrency(using: yAxisMaximum,
                                                          at: CurrencySettings.shared.currencyPosition,
                                                          with: currencySymbol)
            }
        }
    }
}


// MARK: - Accessibility Helpers
//
private extension StoreStatsV4PeriodViewController {

    func updateChartAccessibilityValues() {
        let format = NSLocalizedString(
            "Minimum value %@, maximum value %@",
            comment: "VoiceOver accessibility value, informs the user about the Y-axis min/max values. It reads: Minimum value {value}, maximum value {value}."
        )
        yAxisAccessibilityView.accessibilityValue = String.localizedStringWithFormat(
            format,
            yAxisMinimum,
            yAxisMaximum
        )

        xAxisAccessibilityView.accessibilityValue = String.localizedStringWithFormat(
            NSLocalizedString(
                "Starting period %@, ending period %@",
                comment: "VoiceOver accessibility value, informs the user about the X-axis min/max values. It reads: Starting date {date}, ending date {date}."
            ),
            xAxisMinimum,
            xAxisMaximum
        )

        chartAccessibilityView.accessibilityValue = chartSummaryString()
    }


    func chartSummaryString() -> String {
        guard let dataSet = barChartView.barData?.dataSets.first as? BarChartDataSet, dataSet.count > 0 else {
            return barChartView.noDataText
        }

        var chartSummaryString = ""
        for i in 0..<dataSet.count {
            // We are not including zero value bars here to keep things shorter
            guard let entry = dataSet[safe: i], entry.y != 0.0 else {
                continue
            }

            let entrySummaryString = (entry.accessibilityValue ?? String(entry.y))
            let format = NSLocalizedString(
                "Bar number %i, %@, ",
                comment: "VoiceOver accessibility value about a specific bar in the revenue chart.It reads: Bar number {bar number} {summary of bar}."
            )
            chartSummaryString += String.localizedStringWithFormat(
                format,
                i+1,
                entrySummaryString
            )
        }
        return chartSummaryString
    }
}


// MARK: - Private Helpers
//
private extension StoreStatsV4PeriodViewController {

    func updateSiteVisitDataIfNeeded() {
        if siteStats != nil {
            lastUpdatedDate = Date()
        } else {
            lastUpdatedDate = nil
        }
        siteStatsItems = siteStats?.items?.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.period < rhs.period
        }) ?? []
        reloadSiteFields()
        reloadLastUpdatedField()
    }

    func updateOrderDataIfNeeded() {
        orderStatsIntervals = orderStats?.intervals.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.dateStart() < rhs.dateStart()
        }) ?? []
        if let startDate = orderStatsIntervals.first?.dateStart(),
            let endDate = orderStatsIntervals.last?.dateStart() {
            let timeRangeBarViewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                                   endDate: endDate,
                                                                   timeRange: timeRange,
                                                                   timezone: siteTimezone)
            timeRangeBarView.updateUI(viewModel: timeRangeBarViewModel)
        }

        if !orderStatsIntervals.isEmpty {
            lastUpdatedDate = Date()
        } else {
            lastUpdatedDate = nil
        }
        reloadOrderFields()

        // Don't animate the chart here - this helps avoid a "double animation" effect if a
        // small number of values change (the chart WILL be updated correctly however)
        reloadChart(animateChart: false)
        reloadLastUpdatedField()
    }

    func trackChangedTabIfNeeded() {
        // This is a little bit of a workaround to prevent the "tab tapped" tracks event from firing when launching the app.
        if granularity == .hourly && isInitialLoad {
            isInitialLoad = false
            return
        }
        ServiceLocator.analytics.track(.dashboardMainStatsDate, withProperties: ["range": granularity.rawValue])
        isInitialLoad = false
    }

    func reloadAllFields(animateChart: Bool = true) {
        reloadOrderFields()
        reloadSiteFields()
        reloadChart(animateChart: animateChart)
        reloadLastUpdatedField()
        let visitStatsElements = shouldShowSiteVisitStats ? [visitorsTitle as Any,
                                                             visitorsData as Any]: []
        view.accessibilityElements = visitStatsElements + [ordersTitle as Any,
                                                           ordersData as Any,
                                                           revenueTitle as Any,
                                                           revenueData as Any,
                                                           lastUpdated as Any,
                                                           yAxisAccessibilityView as Any,
                                                           xAxisAccessibilityView as Any,
                                                           chartAccessibilityView as Any]
    }

    func reloadOrderFields() {
        guard ordersData != nil, revenueData != nil else {
            return
        }

        var totalOrdersText = Constants.placeholderText
        var totalRevenueText = Constants.placeholderText
        let currencyCode = CurrencySettings.shared.symbol(from: CurrencySettings.shared.currencyCode)
        if let orderStats = orderStats {
            totalOrdersText = Double(orderStats.totals.totalOrders).humanReadableString()
            totalRevenueText = CurrencyFormatter().formatHumanReadableAmount(String("\(orderStats.totals.grossRevenue)"), with: currencyCode) ?? String()
        }
        ordersData.text = totalOrdersText
        revenueData.text = totalRevenueText
    }

    func reloadSiteFields() {
        guard visitorsData != nil else {
            return
        }

        var visitorsText = Constants.placeholderText
        if let siteStats = siteStats {
            visitorsText = Double(siteStats.totalVisitors).humanReadableString()
        }
        visitorsData.text = visitorsText
    }

    func reloadChart(animateChart: Bool = true) {
        guard barChartView != nil else {
            return
        }
        barChartView.data = generateBarDataSet()
        barChartView.fitBars = true
        barChartView.notifyDataSetChanged()
        if animateChart {
            barChartView.animate(yAxisDuration: Constants.chartAnimationDuration)
        }
        updateChartAccessibilityValues()

        updateUI(hasRevenue: hasRevenue())
    }

    func hasRevenue() -> Bool {
        let totalRevenue = orderStatsIntervals.map({ $0.revenueValue }).reduce(0, +)
        return totalRevenue > 0
    }

    func reloadLastUpdatedField() {
        if lastUpdated != nil { lastUpdated.text = summaryDateUpdated }
    }

    func generateBarDataSet() -> BarChartData? {
        guard !orderStatsIntervals.isEmpty else {
            return nil
        }

        var barCount = 0
        var barColors: [UIColor] = []
        var dataEntries: [BarChartDataEntry] = []
        let currencyCode = CurrencySettings.shared.symbol(from: CurrencySettings.shared.currencyCode)
        orderStatsIntervals.forEach { (item) in
            let entry = BarChartDataEntry(x: Double(barCount), y: (item.revenueValue as NSDecimalNumber).doubleValue)
            let formattedAmount = CurrencyFormatter().formatHumanReadableAmount(String("\(item.revenueValue)"),
                                                                                with: currencyCode,
                                                                                roundSmallNumbers: false) ?? String()
            entry.accessibilityValue = "\(formattedChartMarkerPeriodString(for: item)): \(formattedAmount)"
            barColors.append(.textSubtle)
            dataEntries.append(entry)
            barCount += 1
        }

        let dataSet = BarChartDataSet(entries: dataEntries, label: "Data")
        dataSet.colors = barColors
        dataSet.highlightEnabled = true
        dataSet.highlightColor = .primary
        dataSet.highlightAlpha = Constants.chartHighlightAlpha
        dataSet.drawValuesEnabled = false // Do not draw value labels on the top of the bars
        return BarChartData(dataSet: dataSet)
    }

    func formattedAxisPeriodString(for item: OrderStatsV4Interval) -> String {
        let chartDateFormatter = timeRange.chartDateFormatter(siteTimezone: siteTimezone)
        return chartDateFormatter.string(from: item.dateStart())
    }

    func formattedChartMarkerPeriodString(for item: OrderStatsV4Interval) -> String {
        let chartDateFormatter = timeRange.chartDateFormatter(siteTimezone: siteTimezone)
        return chartDateFormatter.string(from: item.dateStart())
    }
}


// MARK: - Constants!
//
private extension StoreStatsV4PeriodViewController {
    enum Constants {
        static let placeholderText                      = "-"

        static let chartAnimationDuration: TimeInterval = 0.75
        static let chartExtraRightOffset: CGFloat       = 25.0
        static let chartExtraTopOffset: CGFloat         = 20.0
        static let chartHighlightAlpha: CGFloat         = 1.0

        static let chartMarkerInsets: UIEdgeInsets      = UIEdgeInsets(top: 5.0, left: 2.0, bottom: 5.0, right: 2.0)
        static let chartMarkerMinimumSize: CGSize       = CGSize(width: 50.0, height: 30.0)
        static let chartMarkerArrowSize: CGSize         = CGSize(width: 8, height: 6)

        static let chartXAxisGranularity: Double        = 1.0
        static let chartYAxisMinimum: Double            = 0.0
    }
}
