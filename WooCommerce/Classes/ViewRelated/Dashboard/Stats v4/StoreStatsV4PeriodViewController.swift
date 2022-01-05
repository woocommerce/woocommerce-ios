import Charts
import Combine
import UIKit
import Yosemite

/// Different display modes of site visit stats
///
enum SiteVisitStatsMode {
    case `default`
    case redactedDueToJetpack
    case hidden
}

/// Shows the store stats with v4 API for a time range.
///
final class StoreStatsV4PeriodViewController: UIViewController {

    // MARK: - Public Properties

    let granularity: StatsGranularityV4

    var siteVisitStatsMode: SiteVisitStatsMode = .default {
        didSet {
            updateSiteVisitStats(mode: siteVisitStatsMode)
            updateConversionStatsVisibility(visitStatsMode: siteVisitStatsMode)
        }
    }

    /// Updated when reloading data.
    var siteTimezone: TimeZone = .current {
        didSet {
            viewModel.siteTimezone = siteTimezone
        }
    }

    // MARK: - Private Properties
    private let timeRange: StatsTimeRangeV4

    private let viewModel: StoreStatsPeriodViewModel

    // MARK: - Subviews

    @IBOutlet private weak var containerStackView: UIStackView!
    @IBOutlet private weak var visitorsStackView: UIStackView!
    @IBOutlet private weak var visitorsTitle: UILabel!
    @IBOutlet private weak var visitorsData: UILabel!
    @IBOutlet private weak var ordersTitle: UILabel!
    @IBOutlet private weak var ordersData: UILabel!
    @IBOutlet private weak var conversionStackView: UIStackView!
    @IBOutlet private weak var conversionTitle: UILabel!
    @IBOutlet private weak var conversionData: UILabel!
    @IBOutlet private weak var revenueTitle: UILabel!
    @IBOutlet private weak var revenueData: UILabel!
    @IBOutlet private weak var lineChartView: LineChartView!
    @IBOutlet private weak var yAxisAccessibilityView: UIView!
    @IBOutlet private weak var xAxisAccessibilityView: UIView!
    @IBOutlet private weak var chartAccessibilityView: UIView!
    @IBOutlet private weak var noRevenueView: UIView!
    @IBOutlet private weak var noRevenueLabel: UILabel!
    @IBOutlet private weak var timeRangeBarView: StatsTimeRangeBarView!

    private var currencyCode: String {
        return ServiceLocator.currencySettings.symbol(from: ServiceLocator.currencySettings.currencyCode)
    }

    private var orderStatsIntervals: [OrderStatsV4Interval] {
        viewModel.orderStatsIntervals
    }

    private var revenueItems: [Double] {
        orderStatsIntervals.map({ ($0.revenueValue as NSDecimalNumber).doubleValue })
    }

    private var isInitialLoad: Bool = true  // Used in trackChangedTabIfNeeded()

    /// Placeholder: Mockup Charts View
    ///
    private lazy var placeholderChartsView: ChartPlaceholderView = ChartPlaceholderView.instantiateFromNib()


    // MARK: - Computed Properties

    private var currencySymbol: String {
        let code = ServiceLocator.currencySettings.currencyCode
        return ServiceLocator.currencySettings.symbol(from: code)
    }

    // MARK: x/y-Axis Values

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

    private var yAxisMinimum: String {
        let min = revenueItems.min() ?? 0
        return CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).formatHumanReadableAmount(String(min),
                                                             with: currencyCode,
                                                             roundSmallNumbers: false) ?? String()
    }

    private var yAxisMaximum: String {
        let max = revenueItems.max() ?? 0
        return CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).formatHumanReadableAmount(String(max),
                                                             with: currencyCode,
                                                             roundSmallNumbers: false) ?? String()
    }

    private lazy var visitorsEmptyView = StoreStatsSiteVisitEmptyView()

    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Initialization

    /// Designated Initializer
    ///
    init(siteID: Int64,
         timeRange: StatsTimeRangeV4,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         currencyCode: String = ServiceLocator.currencySettings.symbol(from: ServiceLocator.currencySettings.currencyCode)) {
        self.timeRange = timeRange
        self.granularity = timeRange.intervalGranularity
        self.viewModel = StoreStatsPeriodViewModel(siteID: siteID,
                                                   timeRange: timeRange,
                                                   siteTimezone: siteTimezone,
                                                   currencyFormatter: currencyFormatter,
                                                   currencyCode: currencyCode)
        super.init(nibName: type(of: self).nibName, bundle: nil)
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
        observeStatsLabels()
        observeSelectedBarIndex()
        observeTimeRangeBarViewModel()
        observeReloadChartAnimated()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restartGhostAnimationIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadAllFields()
        trackChangedTabIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lineChartView?.clear()
    }
}

// MARK: - Observations for data related updates
private extension StoreStatsV4PeriodViewController {
    func observeStatsLabels() {
        viewModel.orderStatsText.sink { [weak self] orderStatsLabel in
            self?.ordersData.text = orderStatsLabel
        }.store(in: &cancellables)

        viewModel.revenueStatsText.sink { [weak self] revenueStatsLabel in
            self?.revenueData.text = revenueStatsLabel
        }.store(in: &cancellables)

        viewModel.visitorStatsText.sink { [weak self] visitorStatsLabel in
            self?.visitorsData.text = visitorStatsLabel
        }.store(in: &cancellables)

        viewModel.conversionStatsText.sink { [weak self] conversionStatsLabel in
            self?.conversionData.text = conversionStatsLabel
        }.store(in: &cancellables)
    }

    func observeSelectedBarIndex() {
        viewModel.$selectedIntervalIndex.sink { [weak self] selectedIndex in
            guard let self = self else { return }
            let textColor = selectedIndex == nil ? Constants.statsTextColor: Constants.statsHighlightTextColor
            self.ordersData.textColor = textColor
            self.visitorsData.textColor = textColor
            self.revenueData.textColor = textColor
            self.conversionData.textColor = textColor

            self.updateSiteVisitStatsAndConversionRate(selectedIndex: selectedIndex)
        }.store(in: &cancellables)
    }

    func observeTimeRangeBarViewModel() {
        viewModel.timeRangeBarViewModel.sink { [weak self] timeRangeBarViewModel in
            self?.timeRangeBarView.updateUI(viewModel: timeRangeBarViewModel)
        }.store(in: &cancellables)
    }

    func observeReloadChartAnimated() {
        viewModel.reloadChartAnimated.sink { [weak self] animated in
            self?.reloadChart(animateChart: animated)
        }.store(in: &cancellables)
    }
}

// MARK: - Public Interface
//
extension StoreStatsV4PeriodViewController {
    func clearAllFields() {
        lineChartView?.clear()
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

    private func restartGhostAnimationIfNeeded() {
        guard placeholderChartsView.superview != nil else {
            return
        }
        placeholderChartsView.restartGhostAnimation(style: .wooDefaultGhostStyle)
    }
}

// MARK: - Configuration
//
private extension StoreStatsV4PeriodViewController {
    func configureView() {
        view.backgroundColor = Constants.containerBackgroundColor
        containerStackView.backgroundColor = Constants.containerBackgroundColor
        timeRangeBarView.backgroundColor = Constants.headerComponentBackgroundColor
        visitorsStackView.backgroundColor = Constants.headerComponentBackgroundColor

        // Visitor empty view - insert it at the second-to-last index,
        // since we need the footer view (with height = 20) as the last item in the stack view.
        let emptyViewIndex = max(0, visitorsStackView.arrangedSubviews.count - 2)
        visitorsStackView.insertArrangedSubview(visitorsEmptyView, at: emptyViewIndex)
        visitorsEmptyView.isHidden = true

        // Titles
        visitorsTitle.text = NSLocalizedString("Visitors", comment: "Visitors stat label on dashboard - should be plural.")
        ordersTitle.text = NSLocalizedString("Orders", comment: "Orders stat label on dashboard - should be plural.")
        conversionTitle.text = NSLocalizedString("Conversion", comment: "Conversion stat label on dashboard.")
        revenueTitle.text = NSLocalizedString("Revenue", comment: "Revenue stat label on dashboard.")

        [visitorsTitle, ordersTitle, conversionTitle, revenueTitle].forEach { label in
            label?.font = Constants.statsTitleFont
            label?.textColor = Constants.statsTextColor
        }

        // Data
        updateStatsDataToDefaultStyles()

        // Visibility
        updateSiteVisitStats(mode: siteVisitStatsMode)
        updateConversionStatsVisibility(visitStatsMode: siteVisitStatsMode)

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
        noRevenueView.backgroundColor = .systemBackground
        noRevenueLabel.text = NSLocalizedString("No revenue this period",
                                                comment: "Text displayed when no order data are available for the selected time range.")
        noRevenueLabel.font = StyleManager.subheadlineFont
        noRevenueLabel.textColor = .text
    }

    func configureBarChart() {
        lineChartView.marker = StoreStatsChartCircleMarker()
        lineChartView.chartDescription?.enabled = false
        lineChartView.dragEnabled = true
        lineChartView.setScaleEnabled(false)
        lineChartView.pinchZoomEnabled = false
        lineChartView.rightAxis.enabled = false
        lineChartView.legend.enabled = false
        lineChartView.noDataText = NSLocalizedString("No data available", comment: "Text displayed when no data is available for revenue chart.")
        lineChartView.noDataFont = StyleManager.chartLabelFont
        lineChartView.noDataTextColor = .textSubtle
        lineChartView.extraRightOffset = Constants.chartExtraRightOffset
        lineChartView.extraTopOffset = Constants.chartExtraTopOffset
        lineChartView.delegate = self

        let xAxis = lineChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = StyleManager.chartLabelFont
        xAxis.labelTextColor = .textSubtle
        xAxis.axisLineColor = .systemColor(.separator)
        xAxis.gridColor = .systemColor(.separator)
        xAxis.drawLabelsEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.granularity = Constants.chartXAxisGranularity
        xAxis.granularityEnabled = true
        xAxis.valueFormatter = self
        updateChartXAxisLabelCount(xAxis: xAxis, timeRange: timeRange)

        let yAxis = lineChartView.leftAxis
        yAxis.labelFont = StyleManager.chartLabelFont
        yAxis.labelTextColor = .textSubtle
        yAxis.axisLineColor = .systemColor(.separator)
        yAxis.gridColor = .systemColor(.separator)
        yAxis.zeroLineColor = .systemColor(.separator)
        yAxis.drawLabelsEnabled = true
        yAxis.drawGridLinesEnabled = true
        yAxis.drawAxisLineEnabled = false
        yAxis.drawZeroLineEnabled = true
        yAxis.valueFormatter = self
        yAxis.setLabelCount(3, force: true)
    }
}

// MARK: - Internal Updates
private extension StoreStatsV4PeriodViewController {
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
        let xAxis = lineChartView.xAxis
        xAxis.labelTextColor = .textSubtle

        let yAxis = lineChartView.leftAxis
        yAxis.labelTextColor = .textSubtle
    }
}

// MARK: - UI Updates
//
private extension StoreStatsV4PeriodViewController {
    func updateSiteVisitStats(mode: SiteVisitStatsMode) {
        visitorsStackView.isHidden = mode == .hidden
        reloadSiteVisitUI()
        updateConversionStatsVisibility(visitStatsMode: mode)
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
        viewModel.selectedIntervalIndex = selectedIndex
    }

    /// Updates visitor and conversion stats based on the selected bar index.
    ///
    /// - Parameter selectedIndex: the index of interval data for the bar chart. Nil if no bar is selected.
    func updateSiteVisitStatsAndConversionRate(selectedIndex: Int?) {
        let mode: SiteVisitStatsMode

        // Hides site visit stats for "today" when an interval bar is selected.
        if timeRange == .today, selectedIndex != nil {
            mode = .hidden
        } else {
            mode = siteVisitStatsMode
        }

        updateSiteVisitStats(mode: mode)
        updateConversionStatsVisibility(visitStatsMode: mode)

        switch siteVisitStatsMode {
        case .hidden, .redactedDueToJetpack:
            break
        case .default:
            guard selectedIndex != nil else {
                reloadSiteVisitUI()
                return
            }
            guard visitorsData != nil else {
                return
            }
            visitorsData.isHidden = false
            visitorsEmptyView.isHidden = true
        }
    }

    func updateConversionStatsVisibility(visitStatsMode: SiteVisitStatsMode) {
        guard conversionData != nil else {
            return
        }

        switch visitStatsMode {
        case .hidden, .redactedDueToJetpack:
            conversionStackView.isHidden = true
        case .default:
            conversionStackView.isHidden = false
        }
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
            return createOrderStatsIntervalLabels()[Int(value)]
        } else {
            if value == 0.0 {
                // Do not show the "0" label on the Y axis
                return ""
            } else {
                return CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
                                    .formatCurrency(using: value.humanReadableString(),
                                    at: ServiceLocator.currencySettings.currencyPosition,
                                    with: currencySymbol,
                                    isNegative: value.sign == .minus)
            }
        }
    }

    private func createOrderStatsIntervalLabels() -> [String] {
        let helper = StoreStatsV4ChartAxisHelper()
        let intervalDates = orderStatsIntervals.map({ $0.dateStart(timeZone: siteTimezone) })
        return helper.generateLabelText(for: intervalDates,
                                           timeRange: timeRange,
                                           siteTimezone: siteTimezone)
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
        guard let dataSet = lineChartView.lineData?.dataSets.first as? LineChartDataSet, dataSet.count > 0 else {
            return lineChartView.noDataText
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
        viewModel.selectedIntervalIndex = nil
        reloadSiteVisitUI()
        updateConversionStatsVisibility(visitStatsMode: siteVisitStatsMode)
        reloadChart(animateChart: animateChart)
        let visitStatsElements: [Any] = {
            switch siteVisitStatsMode {
            case .default:
                return [visitorsTitle as Any,
                        visitorsData as Any]
            case .redactedDueToJetpack:
                return [visitorsTitle as Any,
                        visitorsEmptyView as Any]
            case .hidden:
                return []
            }
        }()

        view.accessibilityElements = visitStatsElements + [ordersTitle as Any,
                                                           ordersData as Any,
                                                           revenueTitle as Any,
                                                           revenueData as Any,
                                                           conversionTitle as Any,
                                                           conversionData as Any,
                                                           yAxisAccessibilityView as Any,
                                                           xAxisAccessibilityView as Any,
                                                           chartAccessibilityView as Any]
    }

    func reloadSiteVisitUI() {
        switch siteVisitStatsMode {
        case .hidden:
            break
        case .redactedDueToJetpack:
            visitorsData.isHidden = true
            visitorsEmptyView.isHidden = false
        case .default:
            guard visitorsData != nil else {
                return
            }
            visitorsData.isHidden = false
            visitorsEmptyView.isHidden = true
        }
    }

    func reloadChart(animateChart: Bool = true) {
        guard lineChartView != nil else {
            return
        }
        lineChartView.data = generateChartDataSet()
        lineChartView.notifyDataSetChanged()
        if animateChart {
            lineChartView.animate(yAxisDuration: Constants.chartAnimationDuration)
        }
        updateChartAccessibilityValues()

        updateUI(hasRevenue: hasRevenue())
    }

    func hasRevenue() -> Bool {
        return revenueItems.contains { $0 != 0 }
    }

    func generateChartDataSet() -> LineChartData? {
        guard !orderStatsIntervals.isEmpty else {
            return nil
        }

        var barCount = 0
        var barColors: [UIColor] = []
        var dataEntries: [ChartDataEntry] = []
        let currencyCode = ServiceLocator.currencySettings.symbol(from: ServiceLocator.currencySettings.currencyCode)
        orderStatsIntervals.forEach { (item) in
            let entry = ChartDataEntry(x: Double(barCount), y: (item.revenueValue as NSDecimalNumber).doubleValue)
            let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
            let formattedAmount = currencyFormatter.formatHumanReadableAmount(String("\(item.revenueValue)"),
                                                                                with: currencyCode,
                                                                                roundSmallNumbers: false) ?? String()
            entry.accessibilityValue = "\(formattedChartMarkerPeriodString(for: item)): \(formattedAmount)"
            barColors.append(Constants.chartLineColor)
            dataEntries.append(entry)
            barCount += 1
        }

        let hasRevenueData = hasRevenue()

        let dataSet = LineChartDataSet(entries: dataEntries, label: "Data")
        dataSet.drawCirclesEnabled = false
        dataSet.colors = hasRevenueData ? barColors: .init(repeating: .clear, count: barColors.count)
        dataSet.lineWidth = Constants.chartLineWidth
        dataSet.highlightEnabled = hasRevenueData
        dataSet.highlightColor = Constants.chartHighlightLineColor
        dataSet.highlightLineWidth = Constants.chartHighlightLineWidth
        dataSet.drawValuesEnabled = false // Do not draw value labels on the top of the bars
        dataSet.drawHorizontalHighlightIndicatorEnabled = false

        // Configures gradient to fill the area from top to bottom when there is any positive revenue.
        let hasNegativeRevenueOnly = orderStatsIntervals.map { $0.revenueValue }.contains(where: { $0 > 0 }) == false
        if hasRevenueData && !hasNegativeRevenueOnly {
            let gradientColors = [Constants.chartGradientBottomColor.cgColor, Constants.chartGradientTopColor.cgColor] as CFArray
            let gradientColorSpace = CGColorSpaceCreateDeviceRGB()
            let locations: [CGFloat] = hasNegativeRevenueOnly ? [1.0, 0.0]: [0.0, 1.0]
            if let gradient = CGGradient(colorsSpace: gradientColorSpace, colors: gradientColors, locations: locations) {
                dataSet.fill = .init(linearGradient: gradient, angle: 90.0)
                dataSet.fillAlpha = 1.0
                dataSet.drawFilledEnabled = true
            }
        }
        return LineChartData(dataSet: dataSet)
    }

    func formattedAxisPeriodString(for item: OrderStatsV4Interval) -> String {
        let chartDateFormatter = timeRange.chartDateFormatter(siteTimezone: siteTimezone)
        return chartDateFormatter.string(from: item.dateStart(timeZone: siteTimezone))
    }

    func formattedChartMarkerPeriodString(for item: OrderStatsV4Interval) -> String {
        let chartDateFormatter = timeRange.chartDateFormatter(siteTimezone: siteTimezone)
        return chartDateFormatter.string(from: item.dateStart(timeZone: siteTimezone))
    }

    func updateStatsDataToDefaultStyles() {
        [visitorsData, ordersData, conversionData].forEach { label in
            label?.font = Constants.statsFont
            label?.textColor = Constants.statsTextColor
        }
        revenueData.font = Constants.revenueFont
        revenueData.textColor = Constants.statsTextColor
    }
}


// MARK: - Constants!
//
private extension StoreStatsV4PeriodViewController {
    enum Constants {
        static let statsTextColor: UIColor = .text
        static let statsHighlightTextColor: UIColor = .accent
        static let statsFont: UIFont = .font(forStyle: .title3, weight: .semibold)
        static let revenueFont: UIFont = .font(forStyle: .largeTitle, weight: .semibold)
        static let statsTitleFont: UIFont = .caption2

        static let chartAnimationDuration: TimeInterval = 0.75
        static let chartExtraRightOffset: CGFloat       = 25.0
        static let chartExtraTopOffset: CGFloat         = 20.0
        static let chartLineWidth: CGFloat = 2.0
        static let chartHighlightLineWidth: CGFloat = 1.5

        static let chartMarkerInsets: UIEdgeInsets      = UIEdgeInsets(top: 5.0, left: 2.0, bottom: 5.0, right: 2.0)
        static let chartMarkerMinimumSize: CGSize       = CGSize(width: 50.0, height: 30.0)
        static let chartMarkerArrowSize: CGSize         = CGSize(width: 8, height: 6)

        static let chartXAxisGranularity: Double        = 1.0

        static var chartLineColor: UIColor {
            UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade60),
                    dark: .withColorStudio(.wooCommercePurple, shade: .shade30))
        }
        static let chartHighlightLineColor: UIColor = .accent
        static let chartGradientTopColor: UIColor = UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade50).withAlphaComponent(0.1),
                                                            dark: UIColor(red: 204.0/256, green: 204.0/256, blue: 204.0/256, alpha: 0.3))
        static let chartGradientBottomColor: UIColor = .clear.withAlphaComponent(0)

        static let containerBackgroundColor: UIColor = .systemBackground
        static let headerComponentBackgroundColor: UIColor = .clear
    }
}
