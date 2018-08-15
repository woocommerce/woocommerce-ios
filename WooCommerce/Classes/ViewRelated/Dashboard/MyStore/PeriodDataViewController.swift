import UIKit
import Yosemite
import Charts
import XLPagerTabStrip
import WordPressShared
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
    private var lastUpdatedDate: Date?

    public let granularity: StatGranularity
    public var orderStats: OrderStats? {
        didSet {
            lastUpdatedDate = Date()
            reloadOrderFields()
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
}


// MARK: - Public Interface
//
extension PeriodDataViewController {
    func clearAllFields() {
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
    }

    func configureBarChart() {
        barChartView.chartDescription?.enabled = false

        barChartView.dragEnabled = true
        barChartView.setScaleEnabled(true)
        barChartView.pinchZoomEnabled = false

        // ChartYAxis *leftAxis = chartView.leftAxis;

        let xAxis = barChartView.xAxis
        xAxis.labelPosition = .bottom

        barChartView.rightAxis.enabled = false
    }
}


// MARK: - IndicatorInfoProvider Confromance
//
extension PeriodDataViewController {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: granularity.pluralizedString)
    }
}


// MARK: - Private Helpers
//
private extension PeriodDataViewController {

    func reloadAllFields() {
        reloadOrderFields()
        reloadSiteFields()
        reloadLastUpdatedField()
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

    func reloadLastUpdatedField() {
        if lastUpdated != nil { lastUpdated.text = summaryDateUpdated }
    }
}


// MARK: - Constants!
//
private extension PeriodDataViewController {
    enum Constants {
        static let placeholderText = "-"
    }
}
