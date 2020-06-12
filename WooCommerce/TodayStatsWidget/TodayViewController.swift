import UIKit
import NotificationCenter
import Networking
import Yosemite

final class TodayViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    /// Table Sections to be rendered
    ///
    private var sections: [Section] = []

    /// Credentials of the site choosen for showing the stats
    ///
    private var credentials: Credentials?

    /// Site choosed for shoing the stats
    private var site: Site?

    private var totalVisitors: String?
    private var totalOrders: String?
    private var totalRevenue: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        sections = [Section(rows: [.todayStats, .selectedWebsite])]
        credentials = WidgetExtensionService.loadCredentials()
        site = WidgetExtensionService.loadSite()

        syncSiteStats(timeRange: .today)
    }

}

// MARK: - Widget Updating
extension TodayViewController: NCWidgetProviding {

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.newData)
    }

    func syncSiteStats(timeRange: StatsTimeRangeV4,
                            onCompletion: ((Error?) -> Void)? = nil) {

        guard let credentials = credentials else {
            return
        }
        guard let site = site else {
            return
        }

        let network = AlamofireNetwork(credentials: credentials)

        let quantity = timeRange.siteVisitStatsQuantity(date: Date(), siteTimezone: site.siteTimezone)
        let dateFormatter = DateFormatter.Defaults.iso8601WithoutTimeZone
        let earliestDate = dateFormatter.string(from: Date().startOfDay(timezone: TimeZone(secondsFromGMT: 0)!))
        let latestDate = dateFormatter.string(from: Date().endOfDay(timezone: TimeZone(secondsFromGMT: 0)!))
        print(earliestDate)
        print(latestDate)
        //dateFormatter.string(from: timeRange.latestDate(currentDate: Date(), siteTimezone: site.siteTimezone))
        let remoteOrderStats = OrderStatsRemoteV4(network: network)
        remoteOrderStats.loadOrderStats(for: site.siteID, unit: timeRange.intervalGranularity, earliestDateToInclude: earliestDate, latestDateToInclude: latestDate, quantity: quantity) { [weak self] (orderStatsV4, error) in

            if let totalOrdersUnwrapped = orderStatsV4?.totals.totalOrders {
                self?.totalOrders = Double(totalOrdersUnwrapped).humanReadableString()
            }

            // TODO: implement currency formatter
            //let currencyCode = CurrencySettings.shared.symbol(from: CurrencySettings.shared.currencyCode)
            //totalRevenueText = CurrencyFormatter().formatHumanReadableAmount(String("\(orderStats.totals.grossRevenue)"), with: currencyCode) ?? String()

            if let totalRevenueUnwrapped = orderStatsV4?.totals.grossRevenue {
                self?.totalRevenue = String("\(totalRevenueUnwrapped)")
            }

            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }

        let remoteVisitStats = SiteVisitStatsRemote(network: network)
        remoteVisitStats.loadSiteVisitorStats(for: site.siteID,
                                              siteTimezone: site.siteTimezone,
                                    unit: timeRange.siteVisitStatsGranularity,
                                    latestDateToInclude: Date().endOfDay(timezone: site.siteTimezone),
                                    quantity: quantity) { [weak self] (siteVisitStats, error) in
                                        if let totalVisitorsUnwrapped = siteVisitStats?.totalVisitors {
                                            self?.totalVisitors = Double(totalVisitorsUnwrapped).humanReadableString()
                                        }
                                        DispatchQueue.main.async { [weak self] in
                                            self?.tableView.reloadData()
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
        case let cell as SelectedWebsiteInTodayWidgetTableViewCell where row == .selectedWebsite:
            configureSelectedWebsite(cell: cell)
        default:
            fatalError()
            break
        }
    }

    func configureTodayStats(cell: TodayStatsTableViewCell) {
        cell.configure(visitors: totalVisitors ?? "-", orders: totalOrders ?? "-", revenue: totalRevenue ?? "-")
    }

    func configureSelectedWebsite(cell: SelectedWebsiteInTodayWidgetTableViewCell) {
        cell.configure(site: credentials?.siteAddress ?? "-")
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
        case selectedWebsite

        var type: UITableViewCell.Type {
            switch self {
            case .todayStats:
                return TodayStatsTableViewCell.self
            case .selectedWebsite:
                return SelectedWebsiteInTodayWidgetTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
