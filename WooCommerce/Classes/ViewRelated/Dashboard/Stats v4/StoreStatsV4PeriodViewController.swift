import Combine
import UIKit
import struct WordPressUI.GhostStyle
import Yosemite
import WooFoundation

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
    @IBOutlet private weak var lineChartView: UIView!
    @IBOutlet private weak var yAxisAccessibilityView: UIView!
    @IBOutlet private weak var xAxisAccessibilityView: UIView!
    @IBOutlet private weak var chartAccessibilityView: UIView!
    @IBOutlet private weak var noRevenueView: UIView!
    @IBOutlet private weak var noRevenueLabel: UILabel!
    @IBOutlet private weak var timeRangeBarView: StatsTimeRangeBarView!

    private var currencyCode: String {
        return ServiceLocator.currencySettings.symbol(from: ServiceLocator.currencySettings.currencyCode)
    }

    private var orderStatsIntervals: [OrderStatsV4Interval] = [] {
        didSet {
            orderStatsIntervalData = createOrderStatsIntervalData(orderStatsIntervals: orderStatsIntervals)
            configureChart()
        }
    }
    private var orderStatsIntervalData: [ChartData] = []
    private var chartHostingController: UIViewController?

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

    private var cancellables: Set<AnyCancellable> = []
    private let chartValueSelectedEventsSubject = PassthroughSubject<Void, Never>()

    // MARK: - Initialization

    /// Designated Initializer
    ///
    init(siteID: Int64,
         timeRange: StatsTimeRangeV4,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter) {
        self.timeRange = timeRange
        self.granularity = timeRange.intervalGranularity
        self.viewModel = StoreStatsPeriodViewModel(siteID: siteID,
                                                   timeRange: timeRange,
                                                   siteTimezone: siteTimezone,
                                                   currencyFormatter: currencyFormatter,
                                                   currencySettings: currencySettings)
        self.usageTracksEventEmitter = usageTracksEventEmitter
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
        configureNoRevenueView()
        observeStatsLabels()
        observeSelectedBarIndex()
        observeTimeRangeBarViewModel()
        observeOrderStatsIntervals()
        observeVisitorStatsViewState()
        observeConversionStatsViewState()
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
}

// MARK: - Public Interface
//
extension StoreStatsV4PeriodViewController {
    func clearAllFields() {
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

    func configureChart() {
        guard #available(iOS 16, *) else {
            return // fallback to old chart
        }

        if let hostingController = chartHostingController {
            hostingController.removeFromParent()
            hostingController.view.removeFromSuperview()
            remove(hostingController)
        }

        let hostingController = StoreStatsV4ChartHostingController(intervals: orderStatsIntervalData, timeRange: timeRange)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        lineChartView.addSubview(hostingController.view)
        addChild(hostingController)
        hostingController.didMove(toParent: self)
        lineChartView.pinSubviewToAllEdges(hostingController.view)
        self.chartHostingController = hostingController
    }
}

// MARK: - Internal Updates
private extension StoreStatsV4PeriodViewController {
    func updateUI(hasRevenue: Bool) {
        noRevenueView.isHidden = hasRevenue
        updateBarChartAxisUI(hasRevenue: hasRevenue)
    }

    func updateBarChartAxisUI(hasRevenue: Bool) {}
}

private extension StoreStatsV4PeriodViewController {
    /// Updates all stats and time range bar text based on the selected bar index.
    ///
    /// - Parameter selectedIndex: the index of interval data for the bar chart. Nil if no bar is selected.
    func updateUI(selectedBarIndex selectedIndex: Int?) {
        viewModel.selectedIntervalIndex = selectedIndex
    }

    private func createOrderStatsIntervalData(orderStatsIntervals: [OrderStatsV4Interval]) -> [ChartData] {
        let intervalDates = orderStatsIntervals.map { $0.dateStart(timeZone: siteTimezone) }
        let revenues = orderStatsIntervals.map { ($0.revenueValue as NSDecimalNumber).doubleValue }
        return zip(intervalDates, revenues)
            .map { x, y -> ChartData in
                .init(date: x, revenue: y)
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
        return ""
//        guard let dataSet = lineChartView.lineData?.dataSets.first as? LineChartDataSet, dataSet.count > 0 else {
//            return lineChartView.noDataText
//        }
//
//        var chartSummaryString = ""
//        for i in 0..<dataSet.count {
//            // We are not including zero value bars here to keep things shorter
//            guard let entry = dataSet[safe: i], entry.y != 0.0 else {
//                continue
//            }
//
//            let entrySummaryString = (entry.accessibilityValue ?? String(entry.y))
//            let format = NSLocalizedString(
//                "Bar number %i, %@, ",
//                comment: "VoiceOver accessibility value about a specific bar in the revenue chart.It reads: Bar number {bar number} {summary of bar}."
//            )
//            chartSummaryString += String.localizedStringWithFormat(
//                format,
//                i+1,
//                entrySummaryString
//            )
//        }
//        return chartSummaryString
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
        updateChartAccessibilityValues()
        updateUI(hasRevenue: hasRevenue())
    }

    func hasRevenue() -> Bool {
        return revenueItems.contains { $0 != 0 }
    }

//    func generateChartDataSet() -> LineChartData? {
//        guard !orderStatsIntervals.isEmpty else {
//            return nil
//        }
//
//        var barCount = 0
//        var barColors: [UIColor] = []
//        var dataEntries: [ChartDataEntry] = []
//        let currencyCode = ServiceLocator.currencySettings.symbol(from: ServiceLocator.currencySettings.currencyCode)
//        orderStatsIntervals.forEach { (item) in
//            let entry = ChartDataEntry(x: Double(barCount), y: (item.revenueValue as NSDecimalNumber).doubleValue)
//            let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
//            let formattedAmount = currencyFormatter.formatHumanReadableAmount(String("\(item.revenueValue)"),
//                                                                                with: currencyCode,
//                                                                                roundSmallNumbers: false) ?? String()
//            entry.accessibilityValue = "\(formattedChartMarkerPeriodString(for: item)): \(formattedAmount)"
//            barColors.append(Constants.chartLineColor)
//            dataEntries.append(entry)
//            barCount += 1
//        }
//
//        let hasRevenueData = hasRevenue()
//
//        let dataSet = LineChartDataSet(entries: dataEntries, label: "Data")
//        dataSet.drawCirclesEnabled = false
//        dataSet.colors = hasRevenueData ? barColors: .init(repeating: .clear, count: barColors.count)
//        dataSet.lineWidth = Constants.chartLineWidth
//        dataSet.highlightEnabled = hasRevenueData
//        dataSet.highlightColor = Constants.chartHighlightLineColor
//        dataSet.highlightLineWidth = Constants.chartHighlightLineWidth
//        dataSet.drawValuesEnabled = false // Do not draw value labels on the top of the bars
//        dataSet.drawHorizontalHighlightIndicatorEnabled = false
//
//        // Configures gradient to fill the area from top to bottom when there is any positive revenue.
//        let hasNegativeRevenueOnly = orderStatsIntervals.map { $0.revenueValue }.contains(where: { $0 > 0 }) == false
//        if hasRevenueData && !hasNegativeRevenueOnly {
//            let gradientColors = [Constants.chartGradientBottomColor.cgColor, Constants.chartGradientTopColor.cgColor] as CFArray
//            let gradientColorSpace = CGColorSpaceCreateDeviceRGB()
//            let locations: [CGFloat] = [0.0, 1.0]
//            if let gradient = CGGradient(colorsSpace: gradientColorSpace, colors: gradientColors, locations: locations) {
//                dataSet.fill = LinearGradientFill(gradient: gradient, angle: 90.0)
//                dataSet.fillAlpha = 1.0
//                dataSet.drawFilledEnabled = true
//            }
//        }
//        return LineChartData(dataSet: dataSet)
//    }

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
            UIColor(light: .withColorStudio(.wooCommercePurple, shade: .shade50),
                    dark: .withColorStudio(.wooCommercePurple, shade: .shade30))
        }
        static let chartHighlightLineColor: UIColor = .accent
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
