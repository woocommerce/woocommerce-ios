import WidgetKit
import WooFoundation
import KeychainAccess

/// Type that represents the Widget information
///
struct StoreInfoEntry: TimelineEntry {
    /// Date to request new info
    ///
    var date: Date

    /// Eg: Today, Weekly, Monthly, Yearly
    ///
    var range: String

    /// Store name
    ///
    var name: String

    /// Revenue at the range (eg: today)
    ///
    var revenue: String

    /// Visitors count at the range (eg: today)
    ///
    var visitors: String

    /// Order count at the range (eg: today)
    ///
    var orders: String

    /// Conversion at the range (eg: today)
    ///
    var conversion: String
}

/// Type that provides data entries to the widget system.
///
struct StoreInfoProvider: TimelineProvider {

    // TODO: use store currency settings
    private let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

    private let keychain = Keychain(service: "com.automattic.woocommerce", accessGroup: "PZYM8XX95Q.com.automattic.woocommerce")

    /// Redacted entry with sample data.
    ///
    func placeholder(in context: Context) -> StoreInfoEntry {
        StoreInfoEntry(date: Date(),
                       range: "Today",
                       name: "Ernest Shop",
                       revenue: "$132.234",
                       visitors: "67",
                       orders: "23",
                       conversion: "37%")
    }

    /// Quick Snapshot. Required when previewing the widget.
    /// TODO: Update with real data.
    ///
    func getSnapshot(in context: Context, completion: @escaping (StoreInfoEntry) -> Void) {
        completion(placeholder(in: context))
    }

    /// Real data widget.
    ///
    func getTimeline(in context: Context, completion: @escaping (Timeline<StoreInfoEntry>) -> Void) {
        guard let storeIDString = keychain["storeID"],
              let storeID = Int64(storeIDString),
              let authToken = keychain["authToken"],
              let siteName = keychain["siteName"] else {
            // TODO: Handle missing data/logged out state
            completion(errorTimeline(with: StoreWidgetsDataService.NetworkingError.noInputData, in: context))
            return
        }

        let service = StoreWidgetsDataService(authToken: authToken)
        service.fetchDailyStatsData(for: storeID) { result in
            switch result {
            case .success(let storeStats):
                let entry = timelineEntry(for: siteName, storeStats: storeStats)
                let nextRefreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: entry.date) ?? entry.date
                completion(Timeline<StoreInfoEntry>(entries: [entry], policy: .after(nextRefreshDate)))
            case .failure(let error):
                // TODO: Handle networking error
                completion(errorTimeline(with: error, in: context))
            }
        }
    }
}

private extension StoreInfoProvider {

    func placeholderTimeline(in context: Context) -> Timeline<StoreInfoEntry> {
        Timeline<StoreInfoEntry>(entries: [placeholder(in: context)], policy: .never)
    }

    func errorTimeline(with error: Error, in context: Context) -> Timeline<StoreInfoEntry> {
        let entry = StoreInfoEntry(date: Date(),
                                   range: "ERROR",
                                   name: error.localizedDescription,
                                   revenue: "-",
                                   visitors: "-",
                                   orders: "-",
                                   conversion: "-")
        return Timeline<StoreInfoEntry>(entries: [entry], policy: .never)
    }

    func timelineEntry(for siteName: String, storeStats: StoreWidgetsDataService.StoreInfoStats) -> StoreInfoEntry {
        return StoreInfoEntry(date: storeStats.date,
                              range: "Today",
                              name: siteName,
                              revenue: currencyFormatter.formatAmount(storeStats.revenue) ?? "-",
                              visitors: "\(storeStats.totalVisitors)",
                              orders: "\(storeStats.totalOrders)",
                              conversion: "\(storeStats.totalOrders/storeStats.totalVisitors)")
    }
}
