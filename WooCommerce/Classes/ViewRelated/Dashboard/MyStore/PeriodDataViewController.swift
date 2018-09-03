import UIKit
import Yosemite
import Charts
import XLPagerTabStrip
import CocoaLumberjack


class PeriodDataViewController: UIViewController, IndicatorInfoProvider {

    // MARK: - Properties

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
    private var yAxisMinimum: String = Constants.chartYAxisMinimum.friendlyString()
    private var yAxisMaximum: String = ""

    public let granularity: StatGranularity
    public var orderStats: OrderStats? {
        didSet {
            lastUpdatedDate = Date()
            reloadOrderFields()
            reloadChart()
            reloadLastUpdatedField()
        }
    }
    public var siteStats: SiteVisitStats? {
        didSet {
            lastUpdatedDate = Date()
            reloadSiteFields()
            reloadLastUpdatedField()
        }
    }

    // MARK: - Computed Properties

    private var summaryDateUpdated: String {
        if let lastUpdatedDate = lastUpdatedDate {
            return String.localizedStringWithFormat(NSLocalizedString("Updated %@",
                                                                      comment: "Stats summary date"), lastUpdatedDate.mediumString())
        } else {
            return ""
        }
    }

    private var xAxisMinimum: String {
        guard let item = orderStats?.items?.first else {
            return ""
        }
        return formattedPeriodString(for: item)
    }

    private var xAxisMaximum: String {
        guard let item = orderStats?.items?.last else {
            return ""
        }
        return formattedPeriodString(for: item)
    }

    // MARK: - Initialization

    /// Designated Initializer
    ///
    init(granularity: StatGranularity) {
        self.granularity = granularity
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadAllFields()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        clearChartMarkers()
    }
}


// MARK: - Public Interface
//
extension PeriodDataViewController {
    func clearAllFields() {
        barChartView?.clear()
        orderStats = nil
        siteStats = nil
        reloadAllFields()
    }
}


// MARK: - User Interface Configuration
//
private extension PeriodDataViewController {

    func configureView() {
        view.backgroundColor = StyleManager.wooWhite
        borderView.backgroundColor = StyleManager.wooGreyBorder

        // Titles
        visitorsTitle.applyFootnoteStyle()
        ordersTitle.applyFootnoteStyle()
        revenueTitle.applyFootnoteStyle()

        // Data
        visitorsData.applyTitleStyle()
        ordersData.applyTitleStyle()
        revenueData.applyTitleStyle()

        // Footer
        lastUpdated.font = UIFont.footnote
        lastUpdated.textColor = StyleManager.wooGreyMid

        // Accessibility elements
        xAxisAccessibilityView.isAccessibilityElement = true
        xAxisAccessibilityView.accessibilityTraits = UIAccessibilityTraitStaticText
        xAxisAccessibilityView.accessibilityLabel = NSLocalizedString("Store revenue chart: X Axis", comment: "VoiceOver accessibility label for the store revenue chart's X-axis.")
        yAxisAccessibilityView.isAccessibilityElement = true
        yAxisAccessibilityView.accessibilityTraits = UIAccessibilityTraitStaticText
        yAxisAccessibilityView.accessibilityLabel = NSLocalizedString("Store revenue chart: Y Axis", comment: "VoiceOver accessibility label for the store revenue chart's Y-axis.")
        chartAccessibilityView.isAccessibilityElement = true
        chartAccessibilityView.accessibilityTraits = UIAccessibilityTraitImage
        chartAccessibilityView.accessibilityLabel = NSLocalizedString("Store revenue chart", comment: "VoiceOver accessibility label for the store revenue chart.")
        chartAccessibilityView.accessibilityLabel = String.localizedStringWithFormat(NSLocalizedString("Store revenue chart %@",
                                                                                                       comment: "VoiceOver accessibility label for the store revenue chart. It reads: Store revenue chart {chart granularity}."), granularity.pluralizedString)
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
        yAxis.gridLineDashLengths = Constants.chartXAxisDashLengths
        yAxis.axisLineDashPhase = Constants.chartXAxisDashPhase
        yAxis.zeroLineColor = StyleManager.wooGreyBorder
        yAxis.drawLabelsEnabled = true
        yAxis.drawGridLinesEnabled = true
        yAxis.drawAxisLineEnabled = false
        yAxis.drawZeroLineEnabled = true
        yAxis.axisMinimum = Constants.chartYAxisMinimum
        yAxis.valueFormatter = self
    }
}


// MARK: - IndicatorInfoProvider Conformance (Tab Bar)
//
extension PeriodDataViewController {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: granularity.pluralizedString)
    }
}


// MARK: - ChartViewDelegate Conformance (Charts)
//
extension PeriodDataViewController: ChartViewDelegate {
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
extension PeriodDataViewController: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        guard let axis = axis, let orderStats = orderStats else {
            return ""
        }

        if axis is XAxis {
            if let item = orderStats.items?[Int(value)] {
                return formattedPeriodString(for: item)
            } else {
                return ""
            }
        } else {
            if value == 0.0 {
                // Do not show the "0" label on the Y axis
                return ""
            } else {
                yAxisMaximum = value.friendlyString()
                return yAxisMaximum
            }
        }
    }
}


// MARK: - Accessibility Helpers
//
private extension PeriodDataViewController {

    func updateChartAccessibilityValues() {
        yAxisAccessibilityView.accessibilityValue = String.localizedStringWithFormat(NSLocalizedString("Minimum value %@, maximum value %@",
                                                                                                       comment: "VoiceOver accessibility value, informs the user about the Y-axis min/max values. It reads: Minimum value {value}, maximum value {value}."), yAxisMinimum, yAxisMaximum)
        xAxisAccessibilityView.accessibilityValue = String.localizedStringWithFormat(NSLocalizedString("Starting period %@, ending period %@",
                                                                                                       comment: "VoiceOver accessibility value, informs the user about the X-axis min/max values. It reads: Starting date {date}, ending date {date}."), xAxisMinimum, xAxisMaximum)
        chartAccessibilityView.accessibilityValue = chartSummaryString()
    }


    func chartSummaryString() -> String {
        guard let dataSet = barChartView.barData?.dataSets.first as? BarChartDataSet, dataSet.entryCount > 0 else {
            return barChartView.noDataText
        }

        var chartSummaryString = ""
        for i in 0..<dataSet.entryCount {
            // We are not including zero value bars here to keep things shorter
            guard let entry = dataSet.entryForIndex(i), entry.y != 0.0 else {
                continue
            }

            let entrySummaryString = (entry.accessibilityValue ?? String(entry.y))
            chartSummaryString += String.localizedStringWithFormat(NSLocalizedString("Bar number %i, %@, ",
                                                                                     comment: "VoiceOver accessibility value, informs the user about a specific bar in the revenue chart. It reads: Bar number {bar number} {summary of bar}."), i+1, entrySummaryString)
        }
        return chartSummaryString
    }
}


// MARK: - Private Helpers
//
private extension PeriodDataViewController {

    func reloadAllFields() {
        reloadOrderFields()
        reloadSiteFields()
        reloadChart()
        reloadLastUpdatedField()
        view.accessibilityElements = [visitorsTitle, visitorsData, ordersTitle, ordersData, revenueTitle, revenueData, lastUpdated, yAxisAccessibilityView, xAxisAccessibilityView, chartAccessibilityView]
    }

    func reloadOrderFields() {
        guard ordersData != nil, revenueData != nil else {
            return
        }

        var totalOrdersText = Constants.placeholderText
        var totalRevenueText = Constants.placeholderText
        if let orderStats = orderStats {
            totalOrdersText = Double(orderStats.totalOrders).friendlyString()
            let currencySymbol = orderStats.currencySymbol
            let totalRevenue = orderStats.totalSales.friendlyString()
            totalRevenueText = "\(currencySymbol)\(totalRevenue)"
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
            visitorsText = Double(siteStats.totalVisitors).friendlyString()
        }
        visitorsData.text = visitorsText
    }

    func reloadChart() {
        guard barChartView != nil else {
            return
        }
        barChartView.data = generateBarDataSet()
        barChartView.fitBars = true
        barChartView.notifyDataSetChanged()
        barChartView.animate(yAxisDuration: Constants.chartAnimationDuration)
        updateChartAccessibilityValues()
    }

    func reloadLastUpdatedField() {
        if lastUpdated != nil { lastUpdated.text = summaryDateUpdated }
    }

    func clearChartMarkers() {
        barChartView.highlightValue(nil, callDelegate: false)
    }

    func generateBarDataSet() -> BarChartData? {
        guard let orderStats = orderStats, let statItems = orderStats.items, !statItems.isEmpty else {
            return nil
        }

        var barCount = 0
        var dataEntries: [BarChartDataEntry] = []
        statItems.forEach { (item) in
            let entry = BarChartDataEntry(x: Double(barCount), y: item.totalSales)
            entry.accessibilityValue = "\(item.period): \(orderStats.currencySymbol)\(item.totalSales.friendlyString())"
            dataEntries.append(entry)
            barCount += 1
        }

        let dataSet =  BarChartDataSet(values: dataEntries, label: "Data")
        dataSet.setColor(StyleManager.wooCommerceBrandColor)
        dataSet.highlightEnabled = true
        dataSet.highlightColor = StyleManager.wooAccent
        dataSet.highlightAlpha = Constants.chartHighlightAlpha
        dataSet.drawValuesEnabled = false // Do not draw value labels on the top of the bars
        return BarChartData(dataSet: dataSet)
    }

    func formattedPeriodString(for item: OrderStatsItem) -> String {
        var dateString = ""
        switch granularity {
        case .day:
            if let periodDate = DateFormatter.Stats.statsDayFormatter.date(from: item.period) {
                dateString = DateFormatter.Charts.chartsDayFormatter.string(from: periodDate)
            }
        case .week:
            if let periodDate = DateFormatter.Stats.statsWeekFormatter.date(from: item.period) {
                dateString = DateFormatter.Charts.chartsWeekFormatter.string(from: periodDate)
            }
        case .month:
            if let periodDate = DateFormatter.Stats.statsMonthFormatter.date(from: item.period) {
                dateString = DateFormatter.Charts.chartsMonthFormatter.string(from: periodDate)
            }
        case .year:
            if let periodDate = DateFormatter.Stats.statsYearFormatter.date(from: item.period) {
                dateString = DateFormatter.Charts.chartsYearFormatter.string(from: periodDate)
            }
        }
        return dateString
    }
}


// MARK: - Constants!
//
private extension PeriodDataViewController {
    enum Constants {
        static let placeholderText                      = "-"

        static let chartAnimationDuration: TimeInterval = 0.75
        static let chartExtraRightOffset: CGFloat       = 25.0
        static let chartHighlightAlpha: CGFloat         = 1.0

        static let chartMarkerInsets: UIEdgeInsets      = UIEdgeInsets(top: 5.0, left: 2.0, bottom: 5.0, right: 2.0)
        static let chartMarkerMinimumSize: CGSize       = CGSize(width: 50.0, height: 30.0)
        static let chartMarkerArrowSize: CGSize         = CGSize(width: 8, height: 6)

        static let chartXAxisDashLengths: [CGFloat]     = [5.0, 5.0]
        static let chartXAxisDashPhase: CGFloat         = 0.0
        static let chartXAxisGranularity: Double        = 1.0
        static let chartYAxisMinimum: Double            = 0.0
    }
}
