import SwiftUI
import WidgetKit

/// Home-screen widget dispatcher driven by the metric catalog.
///
/// Companion to the legacy `StoreInfoView`; both render the same widget families but consume
/// different shapes off `StoreInfoData`. Selection happens in `StoreInfoHomescreenWidget`
/// based on `useMetricsHomescreenWidget`.
///
struct StoreInfoMetricsView: View {
    let entryData: StoreInfoData

    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                StoreInfoSmallMetricsContainerView(data: entryData)
            case .systemMedium:
                StoreInfoMediumMetricsContainerView(data: entryData)
            case .systemLarge, .systemExtraLarge:
                StoreInfoLargeMetricsContainerView(data: entryData)
            default:
                let _ = assertionFailure("This view only supports system families")
                EmptyView()
            }
        }
        .widgetBackground(backgroundView: Color(.brand))
    }
}

// MARK: - Constants

extension StoreInfoMetricsView {
    enum Localization {
        static let viewMore = AppLocalizedString(
            "storeWidgets.infoView.viewMore",
            value: "View More",
            comment: "Title for the button indicator to display more stats in the Today's Stat widget when using accessibility fonts."
        )
        static func updatedAt(_ updatedTime: String) -> LocalizedString {
            let format = AppLocalizedString("storeWidgets.infoView.updatedAt",
                                            value: "As of %1$@",
                                            comment: "Displays the time when the widget was last updated. %1$@ is the time to render.")
            return LocalizedString.localizedStringWithFormat(format, updatedTime)
        }
    }
}

// MARK: - Previews
#if DEBUG
import class WooFoundation.CurrencySettings

struct StoreInfoMetricsView_Previews: PreviewProvider {
    static var allMetrics: [StoreInfoMetric] {
        let currencySettings = CurrencySettings()
        let revenue = StoreInfoMetric(type: .revenue,
                                      value: .currency(Decimal(123_456_789), currencySettings),
                                      previousValue: .currency(Decimal(118_000_000), currencySettings))
        let orders = StoreInfoMetric(type: .orders,
                                     value: .count(23),
                                     previousValue: .count(31))
        let itemsSold = StoreInfoMetric(type: .itemsSold,
                                        value: .count(41),
                                        previousValue: .count(34))
        let averageOrderValue = StoreInfoMetric(type: .averageOrderValue,
                                                value: .currency(Decimal(5_367), currencySettings),
                                                previousValue: .currency(Decimal(4_800), currencySettings))
        let netSales = StoreInfoMetric(type: .netSales,
                                       value: .currency(Decimal(98_765_432), currencySettings),
                                       previousValue: .currency(Decimal(102_000_000), currencySettings))
        let visitors = StoreInfoMetric(type: .visitors,
                                       value: .count(67),
                                       previousValue: .count(71))
        let conversion = StoreInfoMetric(type: .conversion,
                                         value: .percentage(23.0 / 67.0),
                                         previousValue: .percentage(0.29))

        return [revenue, orders, itemsSold, averageOrderValue, netSales, visitors, conversion]
    }

    static var exampleData: StoreInfoData {
        exampleData(metrics: Array(allMetrics.prefix(4)))
    }

    static var fullCatalogData: StoreInfoData {
        exampleData(metrics: allMetrics)
    }

    static func exampleData(metrics: [StoreInfoMetric]) -> StoreInfoData {
        StoreInfoData(
            range: "Today",
            name: "Ernest Shop",
            revenue: "$123,456,789",
            revenueCompact: "$123M",
            visitors: "67",
            orders: "23",
            conversion: "34%",
            updatedTime: "10:24 PM",
            metrics: metrics
        )
    }

    static var previews: some View {
        StoreInfoMetricsView(entryData: exampleData)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium")

        StoreInfoMetricsView(entryData: exampleData)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.dynamicTypeSize, .xxLarge)
            .previewDisplayName("Medium - XXL font")

        StoreInfoMetricsView(entryData: fullCatalogData)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large")

        StoreInfoMetricsView(entryData: fullCatalogData)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .environment(\.dynamicTypeSize, .xxLarge)
            .previewDisplayName("Large - XXL font")

        StoreInfoMetricsView(entryData: fullCatalogData)
            .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
            .previewDisplayName("Extra Large")

        StoreInfoMetricsView(entryData: fullCatalogData)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small")

        StoreInfoMetricsView(entryData: fullCatalogData)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.dynamicTypeSize, .xxLarge)
            .previewDisplayName("Small - XXL font")
    }
}
#endif
