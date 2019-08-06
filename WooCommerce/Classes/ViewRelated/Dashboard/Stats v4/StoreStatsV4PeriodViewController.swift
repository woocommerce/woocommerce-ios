import Charts
import UIKit
import Yosemite

class StoreStatsV4PeriodViewController: UIViewController {

    // MARK: - Public Properties

    public let granularity: StatsGranularityV4

    var shouldShowSiteVisitStats: Bool = true {
        didSet {
            updateSiteVisitStatsVisibility(shouldShowSiteVisitStats: shouldShowSiteVisitStats)
        }
    }

    // MARK: - Private Properties
    private let timeRange: StatsTimeRangeV4
    private var orderStatsIntervals: [OrderStatsV4Interval] {
        return orderStats?.intervals ?? []
    }
    private var orderStats: OrderStatsV4? {
        return orderStatsResultsController.fetchedObjects.first
    }
    private var siteStats: SiteVisitStats? {
        return siteStatsResultsController.fetchedObjects.first
    }

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

    private var lastUpdatedDate: Date?
    private var yAxisMinimum: String = Constants.chartYAxisMinimum.humanReadableString()
    private var yAxisMaximum: String = ""
    private var isInitialLoad: Bool = true  // Used in trackChangedTabIfNeeded()

    /// SiteVisitStats ResultsController: Loads site visit stats from the Storage Layer
    ///
    private lazy var siteStatsResultsController: ResultsController<StorageSiteVisitStats> = {
        let storageManager = AppDelegate.shared.storageManager
        // TODO-jc: DI date and update FRC on today date change
        let predicate = NSPredicate(format: "granularity ==[c] %@ AND date == %@", timeRange.siteVisitStatsUnitGranularity.rawValue, DateFormatter.Stats.statsDayFormatter.string(from: Date()))
        let descriptor = NSSortDescriptor(keyPath: \StorageSiteVisitStats.date, ascending: false)
        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// OrderStats ResultsController: Loads order stats from the Storage Layer
    ///
    private lazy var orderStatsResultsController: ResultsController<StorageOrderStatsV4> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "timeRange ==[c] %@", timeRange.rawValue)
        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()

    /// Placeholder: Mockup Charts View
    ///
    private lazy var placehoderChartsView: ChartPlaceholderView = ChartPlaceholderView.instantiateFromNib()


    // MARK: - Computed Properties

    private var currencySymbol: String {
        let code = CurrencySettings.shared.currencyCode
        return CurrencySettings.shared.symbol(from: code)
    }

    private var summaryDateUpdated: String {
        if let lastUpdatedDate = lastUpdatedDate {
            return lastUpdatedDate.relativelyFormattedUpdateString
        } else {
            return ""
        }
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
    init(timeRange: StatsTimeRangeV4) {
        self.timeRange = timeRange
        self.granularity = timeRange.intervalGranularity
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
        self.configureView()
        self.configureBarChart()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadAllFields()
        trackChangedTabIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        clearChartMarkers()
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
        placehoderChartsView.startGhostAnimation()
    }

    /// Removes the Placeholder Content.
    /// Why is this public? Because the actual Sync OP is handled by StoreStatsViewController. We coordinate multiple
    /// placeholder animations from that spot!
    ///
    func removeGhostContent() {
        placehoderChartsView.stopGhostAnimation()
        placehoderChartsView.removeFromSuperview()
    }

    /// Ensures the Placeholder Charts UI is onscreen.
    ///
    private func ensurePlaceholderIsVisible() {
        guard placehoderChartsView.superview == nil else {
            return
        }

        placehoderChartsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placehoderChartsView)
        view.pinSubviewToAllEdges(placehoderChartsView)
    }

}

// MARK: - Configuration
//
private extension StoreStatsV4PeriodViewController {

    func configureResultsControllers() {
        // Site Visitor Stats
        siteStatsResultsController.onDidChangeContent = { [weak self] in
            self?.updateSiteVisitDataIfNeeded()
        }
        siteStatsResultsController.onDidResetContent = { [weak self] in
            self?.updateSiteVisitDataIfNeeded()
        }
        try? siteStatsResultsController.performFetch()

        // Order Stats
        orderStatsResultsController.onDidChangeContent = { [weak self] in
            self?.updateOrderDataIfNeeded()
        }
        orderStatsResultsController.onDidResetContent = { [weak self] in
            self?.updateOrderDataIfNeeded()
        }
        try? orderStatsResultsController.performFetch()
    }

    func configureView() {
        view.backgroundColor = StyleManager.wooWhite
        borderView.backgroundColor = StyleManager.wooGreyBorder

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
        lastUpdated.textColor = StyleManager.wooGreyMid

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

    func configureBarChart() {
        barChartView.chartDescription?.enabled = false
        barChartView.dragEnabled = false
        barChartView.setScaleEnabled(false)
        barChartView.pinchZoomEnabled = false
        barChartView.rightAxis.enabled = false
        barChartView.legend.enabled = false
        barChartView.drawValueAboveBarEnabled = true
        barChartView.noDataText = NSLocalizedString("No data available", comment: "Text displayed when no data is available for revenue chart.")
        barChartView.noDataFont = StyleManager.chartLabelFont
        barChartView.noDataTextColor = StyleManager.wooSecondary
        barChartView.extraRightOffset = Constants.chartExtraRightOffset
        barChartView.extraTopOffset = Constants.chartExtraTopOffset
        barChartView.delegate = self

        let xAxis = barChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.setLabelCount(2, force: true)
        xAxis.labelFont = StyleManager.chartLabelFont
        xAxis.labelTextColor = StyleManager.wooSecondary
        xAxis.axisLineColor = StyleManager.wooGreyBorder
        xAxis.gridColor = StyleManager.wooGreyBorder
        xAxis.drawLabelsEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.granularity = Constants.chartXAxisGranularity
        xAxis.granularityEnabled = true
        xAxis.valueFormatter = self

        let yAxis = barChartView.leftAxis
        yAxis.labelFont = StyleManager.chartLabelFont
        yAxis.labelTextColor = StyleManager.wooSecondary
        yAxis.axisLineColor = StyleManager.wooGreyBorder
        yAxis.gridColor = StyleManager.wooGreyBorder
        yAxis.zeroLineColor = StyleManager.wooGreyBorder
        yAxis.drawLabelsEnabled = true
        yAxis.drawGridLinesEnabled = true
        yAxis.drawAxisLineEnabled = false
        yAxis.drawZeroLineEnabled = true
        yAxis.axisMinimum = Constants.chartYAxisMinimum
        yAxis.valueFormatter = self
        yAxis.setLabelCount(3, force: true)
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
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        guard entry.y != 0.0 else {
            // Do not display the marker if the Y-value is zero
            clearChartMarkers()
            return
        }

        let marker = ChartMarker(chartView: chartView,
                                 color: StyleManager.wooSecondary,
                                 font: StyleManager.chartLabelFont,
                                 textColor: StyleManager.wooWhite,
                                 insets: Constants.chartMarkerInsets)
        marker.minimumSize = Constants.chartMarkerMinimumSize
        marker.arrowSize = Constants.chartMarkerArrowSize
        chartView.marker = marker
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
            let item = orderStatsIntervals[Int(value)]
            return formattedAxisPeriodString(for: item)
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
        yAxisAccessibilityView.accessibilityValue = String.localizedStringWithFormat(
            NSLocalizedString(
                "Minimum value %@, maximum value %@",
                comment: "VoiceOver accessibility value, informs the user about the Y-axis min/max values. It reads: Minimum value {value}, maximum value {value}."
            ),
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
            chartSummaryString += String.localizedStringWithFormat(
                NSLocalizedString(
                    "Bar number %i, %@, ",
                    comment: "VoiceOver accessibility value, informs the user about a specific bar in the revenue chart. It reads: Bar number {bar number} {summary of bar}."
                ),
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
        reloadSiteFields()
        reloadLastUpdatedField()
    }

    func updateOrderDataIfNeeded() {
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
        WooAnalytics.shared.track(.dashboardMainStatsDate, withProperties: ["range": granularity.rawValue])
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
    }

    func reloadLastUpdatedField() {
        if lastUpdated != nil { lastUpdated.text = summaryDateUpdated }
    }

    func clearChartMarkers() {
        barChartView.highlightValue(nil, callDelegate: false)
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
            let entry = BarChartDataEntry(x: Double(barCount), y: (item.subtotals.grossRevenue as NSDecimalNumber).doubleValue)
            let formattedAmount = CurrencyFormatter().formatHumanReadableAmount(String("\(item.subtotals.grossRevenue)"),
                                                                                with: currencyCode,
                                                                                roundSmallNumbers: false) ?? String()
            entry.accessibilityValue = "\(formattedChartMarkerPeriodString(for: item)): \(formattedAmount)"
            barColors.append(StyleManager.wooGreyMid)
            dataEntries.append(entry)
            barCount += 1
        }

        let dataSet = BarChartDataSet(entries: dataEntries, label: "Data")
        dataSet.colors = barColors
        dataSet.highlightEnabled = true
        dataSet.highlightColor = StyleManager.wooCommerceBrandColor
        dataSet.highlightAlpha = Constants.chartHighlightAlpha
        dataSet.drawValuesEnabled = false // Do not draw value labels on the top of the bars
        return BarChartData(dataSet: dataSet)
    }

    func formattedAxisPeriodString(for item: OrderStatsV4Interval) -> String {
        var dateString = ""
        // TODO-jc: fix date
        let dateFormatter = DateFormatter.Stats.dateTimeFormatter
        switch granularity {
        case .hourly:
            if let periodDate = dateFormatter.date(from: item.dateStart) {
                dateString = DateFormatter.Charts.chartAxisDayFormatter.string(from: periodDate)
            }
        case .daily:
            if let periodDate = dateFormatter.date(from: item.dateStart) {
                dateString = DateFormatter.Charts.chartAxisWeekFormatter.string(from: periodDate)
            }
        case .weekly:
            if let periodDate = dateFormatter.date(from: item.dateStart) {
                dateString = DateFormatter.Charts.chartAxisMonthFormatter.string(from: periodDate)
            }
        case .monthly:
            if let periodDate = dateFormatter.date(from: item.dateStart) {
                dateString = DateFormatter.Charts.chartAxisYearFormatter.string(from: periodDate)
            }
        default:
            fatalError("This case is not supported: \(granularity.rawValue)")
        }
        return dateString
    }

    func formattedChartMarkerPeriodString(for item: OrderStatsV4Interval) -> String {
        var dateString = ""
        // TODO-jc: fix date
        switch granularity {
        case .hourly:
            if let periodDate = DateFormatter.Stats.statsDayFormatter.date(from: item.dateEnd) {
                dateString = DateFormatter.Charts.chartMarkerDayFormatter.string(from: periodDate)
            }
        case .daily:
            if let periodDate = DateFormatter.Stats.statsWeekFormatter.date(from: item.dateEnd) {
                dateString = DateFormatter.Charts.chartMarkerWeekFormatter.string(from: periodDate)
            }
        case .weekly:
            if let periodDate = DateFormatter.Stats.statsMonthFormatter.date(from: item.dateEnd) {
                dateString = DateFormatter.Charts.chartMarkerMonthFormatter.string(from: periodDate)
            }
        case .monthly:
            if let periodDate = DateFormatter.Stats.statsYearFormatter.date(from: item.dateEnd) {
                dateString = DateFormatter.Charts.chartMarkerYearFormatter.string(from: periodDate)
            }
        default:
            fatalError("This case is not supported: \(granularity.rawValue)")
        }
        return dateString
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
