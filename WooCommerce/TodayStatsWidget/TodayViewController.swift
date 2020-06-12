import UIKit
import NotificationCenter
import Networking
import Yosemite

final class TodayViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    /// Table Sections to be rendered
    ///
    private var sections: [Section] = [] {
           didSet {
               tableView.reloadData()
           }
    }

    /// Credentials of the site choosen for showing the stats
    ///
    private var credentials: Credentials?

    /// Site choosed for shoing the stats
    private var site: Site?

    private var isConfigured: Bool {
        return credentials != nil && site != nil
    }

    private var statsData: StatsData?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }

}

// MARK: - Widget Updating
extension TodayViewController: NCWidgetProviding {

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        retrieveSiteConfiguration()
        fetchData(completionHandler: completionHandler)
    }
}


// MARK: - Private Extension
//
private extension TodayViewController {

    func retrieveSiteConfiguration() {
        credentials = WidgetExtensionService.loadCredentials()
        site = WidgetExtensionService.loadSite()
    }

    func fetchData(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        guard isConfigured else {
            DDLogError("Today Widget: unable to update because is not configured.")

            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
            completionHandler(.failed)
            return
        }

        syncSiteStats(timeRange: .today) { [weak self] (result) in
            switch result {
            case .failed:
                self?.sections = []
                completionHandler(.failed)
                return
            case .newData:
                self?.sections = [Section(rows: [.todayStats])]
                completionHandler(.newData)
                return
            case .noData:
                self?.sections = [Section(rows: [.todayStats])]
                completionHandler(.noData)
                return
            default:
                return
            }
        }
    }

    // Sync remotely all the stats showed in the widget
    func syncSiteStats(timeRange: StatsTimeRangeV4,
                            onCompletion: @escaping (NCUpdateResult) -> Void) {

        guard let credentials = credentials else {
            onCompletion(.failed)
            return
        }
        guard let site = site else {
            onCompletion(.failed)
            return
        }

        var tempStats = StatsData()

        let network = AlamofireNetwork(credentials: credentials)


        /// Calculation of dates
        let dateFormatter = DateFormatter.Defaults.iso8601WithoutTimeZone
        dateFormatter.timeZone = site.siteTimezone
        let earliestDate = dateFormatter.string(from: Date().startOfDay(timezone: site.siteTimezone))
        let latestDate = dateFormatter.string(from: Date().endOfDay(timezone: site.siteTimezone))

        let quantity = timeRange.siteVisitStatsQuantity(date: Date(), siteTimezone: site.siteTimezone)

        let group = DispatchGroup()

        /// Load Visit Stats
        group.enter()
        let remoteVisitStats = SiteVisitStatsRemote(network: network)
        remoteVisitStats.loadSiteVisitorStats(for: site.siteID,
                                              siteTimezone: site.siteTimezone,
                                    unit: timeRange.siteVisitStatsGranularity,
                                    latestDateToInclude: Date().endOfDay(timezone: site.siteTimezone),
                                    quantity: quantity) { (siteVisitStats, error) in
                                        guard error == nil else {
                                            group.leave()
                                            return
                                        }

                                        tempStats.totalVisitors = siteVisitStats?.totalVisitors
                                        group.leave()
        }

        /// Load Order Stats
        group.enter()
        let remoteOrderStats = OrderStatsRemoteV4(network: network)
        remoteOrderStats.loadOrderStats(for: site.siteID, unit: timeRange.intervalGranularity, earliestDateToInclude: earliestDate, latestDateToInclude: latestDate, quantity: quantity) { (orderStatsV4, error) in

            guard error == nil else {
                group.leave()
                return
            }
            tempStats.totalOrders = orderStatsV4?.totals.totalOrders

            // TODO: implement currency formatter
            // let currencyCode = CurrencySettings.shared.symbol(from: CurrencySettings.shared.currencyCode)
            // totalRevenueText = CurrencyFormatter().formatHumanReadableAmount(String("\(orderStats.totals.grossRevenue)"), with: currencyCode) ?? String()

            tempStats.totalRevenue = orderStatsV4?.totals.grossRevenue
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            if tempStats.isVisitStatsEmpty() || tempStats.isOrderStatsEmpty() {
                onCompletion(.failed)
                return
            }

            if tempStats == self?.statsData {
                onCompletion(.noData)
            }
            else {
                self?.statsData = tempStats
                onCompletion(.newData)
            }
        }
    }
}


// MARK: - View Configuration
//
private extension TodayViewController {

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .clear
        tableView.removeLastCellSeparator()

        registerTableViewCells()

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension TodayViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }

}

// MARK: - UITableViewDelegate Conformance
//
extension TodayViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.bounds.size.height
    }
}

// MARK: - Cell configuration
//
private extension TodayViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TodayStatsTableViewCell where row == .todayStats:
            configureTodayStats(cell: cell)
        default:
            fatalError()
            break
        }
    }

    func configureTodayStats(cell: TodayStatsTableViewCell) {
        if let siteURL = site?.url {
            cell.configure(visitors: statsData?.totalVisitorsReadable(), orders: statsData?.totalOrdersReadable(), revenue: statsData?.totalRevenueReadable(), site: siteURL)
        }
    }
}

// MARK: - Private Types
//
private extension TodayViewController {

    struct Section {
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case todayStats

        var type: UITableViewCell.Type {
            switch self {
            case .todayStats:
                return TodayStatsTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

// Stats Data struct
//
struct StatsData: Equatable {
    var totalVisitors: Int?
    var totalOrders: Int?
    var totalRevenue: Decimal?

    func totalVisitorsReadable() -> String {
        guard let totalVisitors = totalVisitors else {
            return "-"
        }
        return Double(totalVisitors).humanReadableString()
    }

    func totalOrdersReadable() -> String {
        guard let totalOrders = totalOrders else {
            return "-"
        }
        return Double(totalOrders).humanReadableString()
    }

    func totalRevenueReadable() -> String {
        guard let totalRevenue = totalRevenue else {
            return "-"
        }
        return String("\(totalRevenue)")
    }

    func isVisitStatsEmpty() -> Bool {
        return totalVisitors == nil
    }

    func isOrderStatsEmpty() -> Bool {
        return totalOrders == nil && totalRevenue == nil
    }
}
