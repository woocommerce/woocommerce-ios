
import WidgetKit
import SwiftUI
import Yosemite
import Networking
import WooFoundation

final class StatsProvider: TimelineProvider {
    // refresh interval of the widget, in minutes
    let refreshInterval = 60

    var service: OrderStatsRemoteV4?

    func placeholder(in context: Context) -> StatsWidgetEntry {
        StatsWidgetEntry.noSite
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsWidgetEntry) -> ()) {
        completion(StatsWidgetEntry.noSite)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsWidgetEntry>) -> ()) {
        guard let defaults = UserDefaults(suiteName: "group.org.wordpress"),
              let storeID = defaults.object(forKey: "storeID") as? Int64,
              let authToken = defaults.string(forKey: "authToken") else {
            debugPrint("no user name found")
            return
        }

//        let keychain = Keychain(service: "com.automattic.woocommerce")
//        guard let authToken = keychain[username] else {
//            print("no token")
//            return
//        }

        let siteName = defaults.string(forKey: "siteName")
        let credentials = Credentials(authToken: authToken)

        let network = AlamofireNetwork(credentials: credentials)
        service = OrderStatsRemoteV4(network: network)
        let date = Date()
        let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: refreshInterval, to: date) ?? date

        let privateCompletion = { (timelineEntry: StatsWidgetEntry) in
            let timeline = Timeline(entries: [timelineEntry], policy: .after(nextRefreshDate))
            completion(timeline)
        }


        service?.loadOrderStats(for: storeID,
                                unit: .daily,
                                earliestDateToInclude: Date().addingTimeInterval(-60*60*24),
                                latestDateToInclude: Date(),
                                quantity: 20) { result in
            switch result {
            case .success(let stats):
                privateCompletion(StatsWidgetEntry.siteSelected(siteName: siteName, stats: stats))
            case .failure(_):
                privateCompletion(.noSite)
            }
        }
    }
}

enum StatsWidgetEntry: TimelineEntry {
    case siteSelected(siteName: String?, stats: OrderStatsV4)
    case noSite

    var date: Date {
        Date()
    }
}

struct WooCommerceStatsWidgetsEntryView: View {
    var entry: StatsProvider.Entry
    let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

    var body: some View {
        switch entry {
        case let .siteSelected(siteName, stats):
            SingleStatView(viewData: GroupedViewData(widgetTitle: "Today",
                                                     siteName: siteName ?? "Your Woo Commerce Store",
                                                     bottomTitle: "Revenue",
                                                     bottomValue: currencyFormatter.formatAmount(stats.totals.netRevenue) ?? "-"))
            .padding()
        case .noSite:
            UnconfiguredView()
        }
    }
}

@main
struct WooCommerceStatsWidgets: Widget {
    let kind: String = "WooCommerceStatsWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatsProvider()) { entry in
            WooCommerceStatsWidgetsEntryView(entry: entry)
        }
    }
}

struct WooCommerceStatsWidgets_Previews: PreviewProvider {
    static var previews: some View {
        WooCommerceStatsWidgetsEntryView(entry: StatsWidgetEntry.noSite)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
