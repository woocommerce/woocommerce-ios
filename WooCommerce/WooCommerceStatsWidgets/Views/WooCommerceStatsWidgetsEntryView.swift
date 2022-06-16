import WidgetKit
import Foundation
import SwiftUI
import WooFoundation

struct WooCommerceStatsWidgetsEntryView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily

    let entry: StatsWidgetsTimelineProvider.Entry
    let title: String
    let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
    let darkPurple = Color(red: 0.407, green: 0.27, blue: 0.603)
    let lightPurple = Color(red: 0.521, green: 0.376, blue: 0.701)

    var body: some View {
        switch entry {
        case .error:
            UnconfiguredView(message: Localization.errorMessage)
        case let .siteSelected(siteName, data):
            switch family {
            case .systemSmall:
                SingleStatView(viewData: SingleStatViewModel(widgetTitle: title,
                                                             siteName: siteName,
                                                             bottomTitle: Localization.revenueTitle,
                                                             bottomValue: currencyFormatter.formatAmount(data.revenue) ?? "-"))
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [darkPurple, lightPurple]), startPoint: .top, endPoint: .bottom))
            case .systemMedium:
                MultiStatsView(viewData: MultiStatViewModel(widgetTitle: title,
                                                            siteName: siteName,
                                                            upperLeftTitle: Localization.revenueTitle,
                                                            upperLeftValue: currencyFormatter.formatAmount(data.revenue) ?? "-",
                                                            upperRightTitle: Localization.visitorsTitle,
                                                            upperRightValue: visitorsString(from: data.visitors),
                                                            lowerLeftTitle: Localization.ordersTitle,
                                                            lowerLeftValue: String(data.orders),
                                                            lowerRightTitle: Localization.conversionTitle,
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

private extension WooCommerceStatsWidgetsEntryView {
    enum Localization {
        static let errorMessage     = NSLocalizedString("Error loading data. Please try again later.",
                                                        comment: "Message when the stats homes creen widget fails to load its data.")
        static let revenueTitle     = NSLocalizedString("Revenue", comment: "Title for the revenue value in the stats home screen widget.")
        static let visitorsTitle    = NSLocalizedString("Visitors", comment: "Title for the visitors value in the stats home screen widget.")
        static let ordersTitle      = NSLocalizedString("Orders", comment: "Title for the orders value in the stats home screen widget.")
        static let conversionTitle  = NSLocalizedString("Conversion", comment: "Title for the conversion value in the stats home screen widget.")
    }
}

struct WooCommerceStatsWidgets_Previews: PreviewProvider {
    static var previews: some View {
        WooCommerceStatsWidgetsEntryView(entry: StatsWidgetEntry.noSite, title: "Today")
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
