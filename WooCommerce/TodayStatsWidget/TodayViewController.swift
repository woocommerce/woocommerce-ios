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
    
    private var isConfigured: Bool {
        return credentials != nil && site != nil
    }
    
    /// Stats data
    private var totalVisitors: String?
    private var totalOrders: String?
    private var totalRevenue: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        sections = [Section(rows: [.todayStats])]
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
        
        
        

        completionHandler(NCUpdateResult.newData)
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
        
        syncSiteStats(timeRange: .today) { (result) in
            let updateResult = try? result.get()
            switch updateResult {
            case .failed:
                return
            case .newData:
                return
            case .noData:
                return
            default:
                return
            }
        }
    }

    // Sync remotely all the stats showed in the widget
    func syncSiteStats(timeRange: StatsTimeRangeV4,
                            onCompletion: (Result<NCUpdateResult, Error>) -> Void) {

        guard let credentials = credentials else {
            return
        }
        guard let site = site else {
            return
        }

        let network = AlamofireNetwork(credentials: credentials)

        let quantity = timeRange.siteVisitStatsQuantity(date: Date(), siteTimezone: site.siteTimezone)

        /// Calculation of dates
        let dateFormatter = DateFormatter.Defaults.iso8601WithoutTimeZone
        dateFormatter.timeZone = site.siteTimezone
        let earliestDate = dateFormatter.string(from: Date().startOfDay(timezone: site.siteTimezone))
        let latestDate = dateFormatter.string(from: Date().endOfDay(timezone: site.siteTimezone))
        
        var isOrderStatsFetched = false
        var isVisitStatsFetched = false
        
        let group = DispatchGroup()
        
        /// Load Order Stats
        group.enter()
        let remoteOrderStats = OrderStatsRemoteV4(network: network)
        remoteOrderStats.loadOrderStats(for: site.siteID, unit: timeRange.intervalGranularity, earliestDateToInclude: earliestDate, latestDateToInclude: latestDate, quantity: quantity) { [weak self] (orderStatsV4, error) in

            guard error != nil else{
                group.leave()
                return
            }
            if let totalOrdersUnwrapped = orderStatsV4?.totals.totalOrders {
                self?.totalOrders = Double(totalOrdersUnwrapped).humanReadableString()
            }

            // TODO: implement currency formatter
            //let currencyCode = CurrencySettings.shared.symbol(from: CurrencySettings.shared.currencyCode)
            //totalRevenueText = CurrencyFormatter().formatHumanReadableAmount(String("\(orderStats.totals.grossRevenue)"), with: currencyCode) ?? String()

            if let totalRevenueUnwrapped = orderStatsV4?.totals.grossRevenue {
                self?.totalRevenue = String("\(totalRevenueUnwrapped)")
            }
            isOrderStatsFetched = true
            group.leave()
        }

        /// Load Visit Stats
        group.enter()
        let remoteVisitStats = SiteVisitStatsRemote(network: network)
        remoteVisitStats.loadSiteVisitorStats(for: site.siteID,
                                              siteTimezone: site.siteTimezone,
                                    unit: timeRange.siteVisitStatsGranularity,
                                    latestDateToInclude: Date().endOfDay(timezone: site.siteTimezone),
                                    quantity: quantity) { [weak self] (siteVisitStats, error) in
                                        guard error != nil else{
                                            group.leave()
                                            return
                                        }
                                        if let totalVisitorsUnwrapped = siteVisitStats?.totalVisitors {
                                            self?.totalVisitors = Double(totalVisitorsUnwrapped).humanReadableString()
                                        }
                                        isVisitStatsFetched = true
                                        group.leave()
        }
        
        group.notify(queue: .main) {
            guard isOrderStatsFetched && isVisitStatsFetched else {
               // completionHandler(.success(NCUpdateResult))
            }
           // completionHandler(.success(NCUpdateResult.newData))
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
            cell.configure(visitors: totalVisitors ?? "-", orders: totalOrders ?? "-", revenue: totalRevenue ?? "-", site: siteURL)
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
