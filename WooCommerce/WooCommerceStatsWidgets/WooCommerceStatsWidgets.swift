
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

    private let placeholderData: StatsWidgetData
    private let earliestDateToInclude: Date
    private var sharedData: SharedData?
    private var statsWidgetsService: StatsWidgetsService?

    private var orderStatsRemoteV4: OrderStatsRemoteV4?
    private var siteVisitStatsRemote: SiteVisitStatsRemote?
    private var network: AlamofireNetwork?

    init(placeholderData: StatsWidgetData, earliestDateToInclude: Date) {
        self.placeholderData = placeholderData
        self.earliestDateToInclude = earliestDateToInclude
        self.sharedData = try? SharedDataManager.retrieveSharedData()

        if let authToken = sharedData?.authToken {
            statsWidgetsService = StatsWidgetsService(authToken: authToken)
        }
    }

    func placeholder(in context: Context) -> StatsWidgetEntry {
        StatsWidgetEntry.siteSelected(siteName: "Your WooCommerce Store", data: placeholderData)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsWidgetEntry) -> ()) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsWidgetEntry>) -> ()) {
        let date = Date()
        let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: refreshInterval, to: date) ?? date
        let privateCompletion = { (timelineEntry: StatsWidgetEntry) in
            let timeline = Timeline(entries: [timelineEntry], policy: .after(nextRefreshDate))
                    completion(timeline)
        }

        guard let sharedData = sharedData,
              let service = statsWidgetsService else {
            return privateCompletion(.noSite)
        }

        Task {
            do {
                let statsWidgetData = try await service.fetchStatsWidgetData(for: sharedData.storeID, earliestDateToInclude: earliestDateToInclude)

                privateCompletion(StatsWidgetEntry.siteSelected(siteName: sharedData.siteName, data: statsWidgetData))
            } catch {
                privateCompletion(.error)
            }
        }
    }
}

enum StatsWidgetEntry: TimelineEntry {
    case error
    case siteSelected(siteName: String, data: StatsWidgetData)
    case noSite

    var date: Date {
        Date()
    }
}

struct WooCommerceStatsWidgetsEntryView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily

    let entry: StatsProvider.Entry
    let title: String
    let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
    let darkPurple = Color(red: 0.407, green: 0.27, blue: 0.603)
    let lightPurple = Color(red: 0.521, green: 0.376, blue: 0.701)

    var body: some View {
        switch entry {
        case .error:
            UnconfiguredView(message: "Error loading data. Please try again later.")
        case let .siteSelected(siteName, data):
            switch family {
            case .systemSmall:
                SingleStatView(viewData: SingleStatViewModel(widgetTitle: title,
                                                             siteName: siteName,
                                                             bottomTitle: "Revenue",
                                                             bottomValue: currencyFormatter.formatAmount(data.revenue) ?? "-"))
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [darkPurple, lightPurple]), startPoint: .top, endPoint: .bottom))
            case .systemMedium:
                MultiStatsView(viewData: MultiStatViewModel(widgetTitle: title,
                                                            siteName: siteName,
                                                            upperLeftTitle: "Revenue",
                                                            upperLeftValue: currencyFormatter.formatAmount(data.revenue) ?? "-",
                                                            upperRightTitle: "Visitors",
                                                            upperRightValue: visitorsString(from: data.visitors),
                                                            lowerLeftTitle: "Orders",
                                                            lowerLeftValue: String(data.orders),
                                                            lowerRightTitle: "Conversion",
                                                            lowerRightValue: conversionRate(from: data.orders, visitors: data.visitors)))
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [darkPurple, lightPurple]), startPoint: .top, endPoint: .bottom))
            default:
                Text("View is unavailable")
            }

        case .noSite:
            UnconfiguredView(message: "Log in to WooCommerce to see today's stats.")
        }
    }

    private func visitorsString(from visitors: Int?) -> String {
        guard let visitors = visitors else {
            return "-"

        }

        return String(visitors)
    }

    private func conversionRate(from orders: Int, visitors: Int?) -> String {
        guard let visitors = visitors else {
            return "-"
        }

        guard visitors > 0 else {
            return "0 %"
        }

        let conversionRate: Double = min(Double(orders) / Double(visitors), 1)
        let rateString = String(format: "%.2f", (conversionRate * 100))

        return "\(rateString)%"
    }
}

struct WooCommerceTodayStatsWidget: Widget {
    let kind: String = "WooCommerceTodayStatsWidget"
    let placeholderData = StatsWidgetData(revenue: 323.12,
                                          orders: 54,
                                          visitors: 143)

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: StatsProvider(placeholderData: placeholderData, earliestDateToInclude: Date().startOfDay())) { entry in
            WooCommerceStatsWidgetsEntryView(entry: entry, title: "Today")
        }
                            .supportedFamilies(FeatureFlagService().widgetsFeatureIsEnabled ? [.systemSmall, .systemMedium] : [])
    }
}

struct WooCommerceThisWeekStatsWidget: Widget {
    let kind: String = "WooCommerceThisWeekStatsWidget"
    let placeholderData = StatsWidgetData(revenue: 1349.21,
                                          orders: 154,
                                          visitors: 686)

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: StatsProvider(placeholderData: placeholderData, earliestDateToInclude: Date().startOfWeek())) { entry in
            WooCommerceStatsWidgetsEntryView(entry: entry, title: "This Week")
        }
                            .supportedFamilies(FeatureFlagService().widgetsFeatureIsEnabled ? [.systemSmall, .systemMedium] : [])
    }
}

struct WooCommerceStatsWidgets_Previews: PreviewProvider {
    static var previews: some View {
        WooCommerceStatsWidgetsEntryView(entry: StatsWidgetEntry.noSite, title: "Today")
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

@main
struct WordPressStatsWidgets: WidgetBundle {
    var body: some Widget {
        WooCommerceTodayStatsWidget()
        WooCommerceThisWeekStatsWidget()
    }
}

/// Ideally we use the Feature Flag implementation from the Experiments target, but it failed to compile when importing.
/// We should fix it and use it here.
struct FeatureFlagService {
    let widgetsFeatureIsEnabled = true
}
