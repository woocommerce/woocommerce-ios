
import WidgetKit
import SwiftUI
import Yosemite
import Networking
import WooFoundation

enum StatsProviderError: Error {
    case attemptToRequestWithoutNetworkSet
}

final class StatsProvider: TimelineProvider {
    // refresh interval of the widget, in minutes
    let refreshInterval = 60

    var orderStatsRemoteV4: OrderStatsRemoteV4?
    var siteVisitStatsRemote: SiteVisitStatsRemote?
    var network: AlamofireNetwork?

    func placeholder(in context: Context) -> StatsWidgetEntry {
        StatsWidgetEntry.noSite
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsWidgetEntry) -> ()) {
        completion(StatsWidgetEntry.noSite)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsWidgetEntry>) -> ()) {
        let date = Date()
        let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: refreshInterval, to: date) ?? date

        let privateCompletion = { (timelineEntry: StatsWidgetEntry) in
            let timeline = Timeline(entries: [timelineEntry], policy: .after(nextRefreshDate))
                    completion(timeline)
        }

        guard let defaults = UserDefaults(suiteName: "group.org.wordpress"),
              let storeID = defaults.object(forKey: "storeID") as? Int64,
              let authToken = defaults.string(forKey: "authToken") else {
            debugPrint("no user name found")
            return privateCompletion(.noSite)
        }

        let siteName = defaults.string(forKey: "siteName")
        let credentials = Credentials(authToken: authToken)

        network = AlamofireNetwork(credentials: credentials)
        Task {
            do {
                async let orderStats = loadOrderStats(for: storeID)
                async let visitStats = loadSiteVisitorStats(for: storeID)

                privateCompletion(StatsWidgetEntry.siteSelected(siteName: siteName, orderStats: try await orderStats, visitStat: try? await visitStats))
            } catch {
                privateCompletion(.error)
            }
        }
    }

    func loadSiteVisitorStats(for storeID: Int64) async throws -> SiteVisitStats {
        if siteVisitStatsRemote == nil {
            guard let network = network else {
                throw StatsProviderError.attemptToRequestWithoutNetworkSet
            }


            siteVisitStatsRemote = SiteVisitStatsRemote(network: network)
        }


        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                siteVisitStatsRemote?.loadSiteVisitorStats(for: storeID,
                                        unit: .day,
                                        latestDateToInclude: Date(),
                                        quantity: 1) { result in
                    switch result {
                    case .success(_):
                        continuation.resume(with: result)

                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }

    }

    func loadOrderStats(for storeID: Int64) async throws -> OrderStatsV4 {
        if orderStatsRemoteV4 == nil {
            guard let network = network else {
                throw StatsProviderError.attemptToRequestWithoutNetworkSet
            }


            orderStatsRemoteV4 = OrderStatsRemoteV4(network: network)
        }


        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                orderStatsRemoteV4?.loadOrderStats(for: storeID,
                                        unit: .daily,
                                        earliestDateToInclude: Date().addingTimeInterval(-60*60*24),
                                        latestDateToInclude: Date(),
                                        quantity: 20) { result in
                    switch result {
                    case .success(_):
                        continuation.resume(with: result)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

}

enum StatsWidgetEntry: TimelineEntry {
    case error
    case siteSelected(siteName: String?, orderStats: OrderStatsV4, visitStat: SiteVisitStats?)
    case noSite

    var date: Date {
        Date()
    }
}

struct WooCommerceStatsWidgetsEntryView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily

    var entry: StatsProvider.Entry
    let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
    let darkPurple = Color(red: 0.407, green: 0.27, blue: 0.603)
    let lightPurple = Color(red: 0.521, green: 0.376, blue: 0.701)

    var body: some View {
        switch entry {
        case .error:
            UnconfiguredView(message: "Error loading data. Please try again later.")
        case let .siteSelected(siteName, orderStats, visitStats):
            switch family {
            case .systemSmall:
                SingleStatView(viewData: SingleStatViewModel(widgetTitle: "Today",
                                                         siteName: siteName ?? "Your Woo Commerce Store",
                                                         bottomTitle: "Revenue",
                                                         bottomValue: currencyFormatter.formatAmount(orderStats.totals.netRevenue) ?? "-"))
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [darkPurple, lightPurple]), startPoint: .top, endPoint: .bottom))
            case .systemMedium:
                MultiStatsView(viewData: MultiStatViewModel(widgetTitle: "Today",
                                                            siteName: siteName ?? "Your Woo Commerce Store",
                                                            upperLeftTitle: "Revenue",
                                                            upperLeftValue: currencyFormatter.formatAmount(orderStats.totals.netRevenue) ?? "-",
                                                            upperRightTitle: "Visitors",
                                                            upperRightValue: visitorsString(from: visitStats),
                                                            lowerLeftTitle: "Orders",
                                                            lowerLeftValue: String(orderStats.totals.totalOrders),
                                                            lowerRightTitle: "Conversion",
                                                            lowerRightValue: conversionRate(from: orderStats, visitStats: visitStats)))
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [darkPurple, lightPurple]), startPoint: .top, endPoint: .bottom))
            default:
                Text("View is unavailable")
            }

        case .noSite:
            UnconfiguredView(message: "Log in to WooCommerce to see today's stats.")
        }
    }

    private func visitorsString(from visitStats: SiteVisitStats?) -> String {
        guard let visitors = visitStats?.items?.first?.visitors else {
            return "-"

        }

        return String(visitors)
    }

    private func conversionRate(from orderStats: OrderStatsV4, visitStats: SiteVisitStats?) -> String {
        guard let visitors = visitStats?.items?.first?.visitors else {
            return "-"
        }

        let conversionRate = visitors > 0 ? min(orderStats.totals.totalOrders/visitors, 1): 0

        return "\(conversionRate * 100) %"
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
