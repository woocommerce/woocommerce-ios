import DGCharts
import Combine
import UIKit
import WordPressUI
import Yosemite
import WooFoundation

/// Different display modes of site visit stats
///
enum SiteVisitStatsMode {
    case `default`
    case redactedDueToJetpack
    case hidden
    case redactedDueToCustomRange
}

/// Shows the store stats with v4 API for a time range.
///
final class StoreStatsV4PeriodViewController: UIViewController {

    // MARK: - Public Properties

    let granularity: StatsGranularityV4

    var siteVisitStatsMode: SiteVisitStatsMode = .default {
        didSet {
            viewModel.siteVisitStatsMode = siteVisitStatsMode
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

    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter

    private let stores: StoresManager

    // MARK: - Subviews

    @IBOutlet private weak var containerStackView: UIStackView!
    @IBOutlet private weak var visitorsTitle: UILabel!
    @IBOutlet private weak var visitorsDataOrRedactedView: StoreStatsDataOrRedactedView!
    @IBOutlet private weak var ordersTitle: UILabel!
    @IBOutlet private weak var ordersDataOrRedactedView: StoreStatsDataOrRedactedView!
    @IBOutlet private weak var conversionTitle: UILabel!
    @IBOutlet private weak var conversionDataOrRedactedView: StoreStatsDataOrRedactedView!
    @IBOutlet private weak var revenueTitle: UILabel!
    @IBOutlet private weak var revenueData: UILabel!
    @IBOutlet private weak var lineChartView: LineChartView!
    @IBOutlet private weak var yAxisAccessibilityView: UIView!
    @IBOutlet private weak var xAxisAccessibilityView: UIView!
    @IBOutlet private weak var chartAccessibilityView: UIView!
    @IBOutlet private weak var noRevenueView: UIView!
    @IBOutlet private weak var noRevenueLabel: UILabel!
    @IBOutlet private weak var timeRangeBarView: StatsTimeRangeBarView!
    @IBOutlet private weak var visitorsStackView: UIStackView!
    @IBOutlet private weak var conversionStackView: UIStackView!
    @IBOutlet private weak var granularityLabel: UILabel!

    private var currencyCode: String {
        return ServiceLocator.currencySettings.symbol(from: ServiceLocator.currencySettings.currencyCode)
    }

    private var orderStatsIntervals: [OrderStatsV4Interval] = [] {
        didSet {
            orderStatsIntervalLabels = createOrderStatsIntervalLabels(orderStatsIntervals: orderStatsIntervals)
        }
    }
    private var orderStatsIntervalLabels: [String] = []

    private var revenueItems: [Double] {
        orderStatsIntervals.map({ ($0.revenueValue as NSDecimalNumber).doubleValue })
    }

    private var isInitialLoad: Bool = true  // Used in trackChangedTabIfNeeded()

    // To check whether the tab is showing the visitors and conversion views as redacted for custom range.
    // This redaction is only shown on Custom Range tab with WordPress.com or Jetpack connected sites,
    // while Jetpack CP sites has its own redacted for Jetpack state, and non-Jetpack sites simply has them empty.
    private var unavailableVisitStatsDueToCustomRange: Bool {
        guard timeRange.isCustomTimeRange,
              let site = stores.sessionManager.defaultSite,
              site.isJetpackConnected,
              site.isJetpackThePluginInstalled else {
            return false
        }
        return true
    }

    /// Placeholder: Mockup Charts View
    ///
    private lazy var placeholderChartsView: ChartPlaceholderView = ChartPlaceholderView.instantiateFromNib()

    /// Information alert for custom range tab redaction
    ///
    private lazy var fancyAlert = FancyAlertViewController.makeCustomRangeRedactionInformationAlert()

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

    private var cancellables: Set<AnyCancellable> = []
    private let chartValueSelectedEventsSubject = PassthroughSubject<Void, Never>()
    private let editCustomTimeRangeHandler: (() -> Void)?

    // MARK: - Initialization

    /// Designated Initializer
    ///
    init(siteID: Int64,
         timeRange: StatsTimeRangeV4,
         currentDate: Date,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter,
         stores: StoresManager = ServiceLocator.stores,
         onEditCustomTimeRange: (() -> Void)?) {
        self.timeRange = timeRange
        self.granularity = timeRange.intervalGranularity
        self.viewModel = StoreStatsPeriodViewModel(siteID: siteID,
                                                   timeRange: timeRange,
                                                   siteTimezone: siteTimezone,
                                                   currentDate: currentDate,
                                                   currencyFormatter: currencyFormatter,
                                                   currencySettings: currencySettings)
        self.usageTracksEventEmitter = usageTracksEventEmitter
        self.stores = stores
        self.editCustomTimeRangeHandler = onEditCustomTimeRange
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
        configureChart()
        configureNoRevenueView()
        observeStatsLabels()
        observeSelectedBarIndex()
        observeTimeRangeBarViewModel()
        observeOrderStatsIntervals()
        observeVisitorStatsViewState()
        observeConversionStatsViewState()
        observeYAxisMaximum()
        observeYAxisMinimum()
        observeChartValueSelectedEvents()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // After returning to the My Store tab, `restartGhostAnimation` is required to resume ghost animation.
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
            self?.ordersDataOrRedactedView.data = orderStatsLabel
        }.store(in: &cancellables)

        viewModel.revenueStatsText.sink { [weak self] revenueStatsLabel in
            self?.revenueData.text = revenueStatsLabel
        }.store(in: &cancellables)

        viewModel.visitorStatsText.sink { [weak self] visitorStatsLabel in
            self?.visitorsDataOrRedactedView.data = visitorStatsLabel
        }.store(in: &cancellables)

        viewModel.conversionStatsText.sink { [weak self] conversionStatsLabel in
            self?.conversionDataOrRedactedView.data = conversionStatsLabel
        }.store(in: &cancellables)
    }

    func observeSelectedBarIndex() {
        viewModel.$selectedIntervalIndex.sink { [weak self] selectedIndex in
            guard let self = self else { return }
            let isHighlighted = selectedIndex != nil
            let textColor = isHighlighted ? Constants.statsHighlightTextColor: Constants.statsTextColor
            self.ordersDataOrRedactedView.isHighlighted = isHighlighted
            self.visitorsDataOrRedactedView.isHighlighted = isHighlighted
            self.conversionDataOrRedactedView.isHighlighted = isHighlighted
            self.revenueData.textColor = textColor
        }.store(in: &cancellables)
    }

    func observeTimeRangeBarViewModel() {
        viewModel.timeRangeBarViewModel.sink { [weak self] timeRangeBarViewModel in
            self?.timeRangeBarView.updateUI(viewModel: timeRangeBarViewModel)
        }.store(in: &cancellables)
    }

    func observeOrderStatsIntervals() {
        viewModel.orderStatsIntervals.sink { [weak self] orderStatsIntervals in
            guard let self = self else { return }

            self.orderStatsIntervals = orderStatsIntervals

            // Don't animate the chart here - this helps avoid a "double animation" effect if a
            // small number of values change (the chart WILL be updated correctly however)
            self.reloadChart(animateChart: false)
        }.store(in: &cancellables)
    }

    func observeVisitorStatsViewState() {
        viewModel.visitorStatsViewState
            .sink { [weak self] viewState in
                guard let self = self, self.visitorsDataOrRedactedView != nil else { return }
                self.visitorsDataOrRedactedView.state = viewState
        }.store(in: &cancellables)
    }

    func observeConversionStatsViewState() {
        viewModel.conversionStatsViewState
            .sink { [weak self] viewState in
                guard let self = self, self.conversionDataOrRedactedView != nil else { return }
                self.conversionDataOrRedactedView.state = viewState
        }.store(in: &cancellables)
    }

    func observeYAxisMaximum() {
        viewModel.yAxisMaximum.sink { [weak self] yAxisMaximum in
            self?.lineChartView.leftAxis.axisMaximum = yAxisMaximum
        }.store(in: &cancellables)
    }

    func observeYAxisMinimum() {
        viewModel.yAxisMinimum.sink { [weak self] yAxisMinimum in
            self?.lineChartView.leftAxis.axisMinimum = yAxisMinimum
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
        placeholderChartsView.startGhostAnimation(style: Constants.ghostStyle)
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
        placeholderChartsView.restartGhostAnimation(style: Constants.ghostStyle)
    }
}

// MARK: - Configuration
//
private extension StoreStatsV4PeriodViewController {
    func configureView() {
        view.backgroundColor = Constants.containerBackgroundColor
        containerStackView.backgroundColor = Constants.containerBackgroundColor
        timeRangeBarView.backgroundColor = Constants.headerComponentBackgroundColor
        timeRangeBarView.editCustomTimeRangeHandler = editCustomTimeRangeHandler

        // Titles
        visitorsTitle.text = NSLocalizedString("Visitors", comment: "Visitors stat label on dashboard - should be plural.")
        ordersTitle.text = NSLocalizedString("Orders", comment: "Orders stat label on dashboard - should be plural.")
        conversionTitle.text = NSLocalizedString("Conversion", comment: "Conversion stat label on dashboard.")
        revenueTitle.text = NSLocalizedString("Revenue", comment: "Revenue stat label on dashboard.")

        [visitorsTitle, ordersTitle, conversionTitle, revenueTitle, granularityLabel].forEach { label in
            label?.font = Constants.statsTitleFont
            label?.textColor = Constants.statsTextColor
        }

        // Granularity text
        granularityLabel.text = granularity.displayText
        granularityLabel.textAlignment = .center
        granularityLabel.isHidden = timeRange.isCustomTimeRange == false

        // Data
        updateStatsDataToDefaultStyles()

        // Taps
        if unavailableVisitStatsDueToCustomRange {
            fancyAlert.modalPresentationStyle = .custom
            fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController

            let visitorsTapRecognizer = UITapGestureRecognizer()
            visitorsTapRecognizer.on { [weak self] _ in
                guard let self,
                      siteVisitStatsMode == .redactedDueToCustomRange
                else { return }

                present(fancyAlert, animated: true)
            }

            let conversionTapRecognizer = UITapGestureRecognizer()
            conversionTapRecognizer.on { [weak self] _ in
                guard let self,
                      siteVisitStatsMode == .redactedDueToCustomRange
                else { return }

                present(fancyAlert, animated: true)
            }

            visitorsStackView.addGestureRecognizer(visitorsTapRecognizer)
            visitorsStackView.isUserInteractionEnabled = true

            conversionStackView.addGestureRecognizer(conversionTapRecognizer)
            conversionStackView.isUserInteractionEnabled = true
        }

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
        chartAccessibilityView.accessibilityIdentifier = "chart-image"
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

    func configureChart() {
        lineChartView.marker = StoreStatsChartCircleMarker()
        lineChartView.chartDescription.enabled = false
        lineChartView.dragXEnabled = true
        lineChartView.dragYEnabled = false
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
        xAxis.yOffset = 8
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

        chartValueSelectedEventsSubject.send()
    }

    /// Observe `chartValueSelected` events and call `StoreStatsUsageTracksEventEmitter.interacted()` when
    /// no similar events have been received after some time.
    ///
    /// We debounce it because there are just too many events received from `chartValueSelected()` when
    /// the user holds and drags on the chart. Having too many events might skew the
    /// `StoreStatsUsageTracksEventEmitter` algorithm.
    private func observeChartValueSelectedEvents() {
        chartValueSelectedEventsSubject
            .debounce(for: .seconds(Constants.chartValueSelectedEventsDebounce), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if self.timeRange.isCustomTimeRange {
                    ServiceLocator.analytics.track(event: .DashboardCustomRange.interacted())
                }
                self.usageTracksEventEmitter.interacted()
            }.store(in: &cancellables)
    }
}

private extension StoreStatsV4PeriodViewController {
    /// Updates all stats and time range bar text based on the selected bar index.
    ///
    /// - Parameter selectedIndex: the index of interval data for the bar chart. Nil if no bar is selected.
    func updateUI(selectedBarIndex selectedIndex: Int?) {

        if unavailableVisitStatsDueToCustomRange {
            // If time range is less than 2 days, redact data when selected and show when deselected.
            // Otherwise, show data when selected and redact when deselected.
            guard case let .custom(from, to) = timeRange,
                  let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, endDate: to) else {
                return
            }

            if differenceInDays == .sameDay {
                siteVisitStatsMode = selectedIndex != nil ? .hidden : .default
            } else {
                siteVisitStatsMode = selectedIndex != nil ? .default : .redactedDueToCustomRange
            }
        }

        viewModel.selectedIntervalIndex = selectedIndex
    }
}

// MARK: - AxisValueFormatter Conformance (Charts)
//
extension StoreStatsV4PeriodViewController: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        guard let axis = axis else {
            return ""
        }

        if axis is XAxis {
            let intervalLabels = orderStatsIntervalLabels
            let index = Int(value)
            if index >= intervalLabels.count {
                DDLogInfo("🔴 orderStatsIntervals count: \(orderStatsIntervals.count); value: \(value); index: \(index); interval labels: \(intervalLabels)")
            }
            return intervalLabels[safe: index] ?? ""
        } else {
            if value == 0.0 {
                // Do not show the "0" label on the Y axis
                return ""
            } else if hasRevenue() == false {
                // Extra spaces are necessary so that the first x-axis label is not truncated.
                return "   "
            } else {
                return CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
                    .formatCurrency(using: value.humanReadableString(shouldHideDecimalsForIntegerAbbreviatedValue: true),
                                    currencyPosition: ServiceLocator.currencySettings.currencyPosition,
                                    currencySymbol: currencySymbol,
                                    isNegative: value.sign == .minus)
            }
        }
    }

    private func createOrderStatsIntervalLabels(orderStatsIntervals: [OrderStatsV4Interval]) -> [String] {
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
        usageTracksEventEmitter.interacted()
        ServiceLocator.analytics.track(event: .Dashboard.dashboardMainStatsDate(timeRange: timeRange))
        isInitialLoad = false
    }

    func reloadAllFields(animateChart: Bool = true) {
        viewModel.selectedIntervalIndex = nil
        reloadChart(animateChart: animateChart)

        view.accessibilityElements = [ordersTitle as Any,
                                      ordersDataOrRedactedView as Any,
                                      visitorsTitle as Any,
                                      visitorsDataOrRedactedView as Any,
                                      revenueTitle as Any,
                                      revenueData as Any,
                                      conversionTitle as Any,
                                      conversionDataOrRedactedView as Any,
                                      yAxisAccessibilityView as Any,
                                      xAxisAccessibilityView as Any,
                                      chartAccessibilityView as Any]
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
            let locations: [CGFloat] = [0.0, 1.0]
            if let gradient = CGGradient(colorsSpace: gradientColorSpace, colors: gradientColors, locations: locations) {
                dataSet.fill = LinearGradientFill(gradient: gradient, angle: 90.0)
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
        revenueData.font = Constants.revenueFont
        revenueData.textColor = Constants.statsTextColor
        revenueData.adjustsFontSizeToFitWidth = true
        revenueData.accessibilityIdentifier = "revenue-value"
    }
}


// MARK: - Constants!
//
private extension StoreStatsV4PeriodViewController {
    enum Constants {
        static let statsTextColor: UIColor = .text
        static let statsHighlightTextColor: UIColor = .statsHighlighted
        static let revenueFont: UIFont = .font(forStyle: .largeTitle, weight: .semibold)
        static let statsTitleFont: UIFont = StyleManager.statsTitleFont

        static let chartAnimationDuration: TimeInterval = 0.75
        static let chartExtraRightOffset: CGFloat       = 25.0
        static let chartExtraTopOffset: CGFloat         = 20.0
        static let chartLineWidth: CGFloat = 2.0
        static let chartHighlightLineWidth: CGFloat = 1.5

        static let chartMarkerInsets: UIEdgeInsets      = UIEdgeInsets(top: 5.0, left: 2.0, bottom: 5.0, right: 2.0)
        static let chartMarkerMinimumSize: CGSize       = CGSize(width: 50.0, height: 30.0)
        static let chartMarkerArrowSize: CGSize         = CGSize(width: 8, height: 6)

        static let chartXAxisGranularity: Double        = 1.0

        static var chartLineColor: UIColor = .accent
        static let chartHighlightLineColor: UIColor = .statsHighlighted
        static let chartGradientTopColor: UIColor = UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade50).withAlphaComponent(0.1),
                                                            dark: UIColor(red: 204.0/256, green: 204.0/256, blue: 204.0/256, alpha: 0.3))
        static let chartGradientBottomColor: UIColor = .clear.withAlphaComponent(0)

        static let containerBackgroundColor: UIColor = .systemBackground
        static let headerComponentBackgroundColor: UIColor = .clear

        static let ghostStyle: GhostStyle = .wooDefaultGhostStyle

        /// The wait time before the `StoreStatsUsageTracksEventEmitter.interacted()` is called.
        static let chartValueSelectedEventsDebounce: TimeInterval = 1.0
    }
}
