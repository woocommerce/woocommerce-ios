import WidgetKit
import Foundation
import SwiftUI
import WooFoundation

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

struct WooCommerceStatsWidgets_Previews: PreviewProvider {
    static var previews: some View {
        WooCommerceStatsWidgetsEntryView(entry: StatsWidgetEntry.noSite, title: "Today")
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
