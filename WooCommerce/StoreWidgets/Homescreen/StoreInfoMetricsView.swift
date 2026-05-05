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
                StoreInfoSmallMetricsView(data: entryData)
            case .systemMedium, .systemLarge, .systemExtraLarge:
                StoreInfoMediumMetricsView(data: entryData)
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
    static var exampleData = StoreInfoData(
        range: "Today",
        name: "Ernest Shop",
        revenue: "$123,456,789",
        revenueCompact: "$123M",
        visitors: "67",
        orders: "23",
        conversion: "34%",
        updatedTime: "10:24 PM",
        metrics: [
            .init(type: .revenue, value: .currency(123_456_789, CurrencySettings())),
            .init(type: .visitors, value: .count(67)),
            .init(type: .orders, value: .count(23)),
            .init(type: .conversion, value: .percentage(23.0 / 67.0))
        ]
    )

    static var previews: some View {
        StoreInfoMetricsView(entryData: exampleData)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium")

        StoreInfoMetricsView(entryData: exampleData)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.dynamicTypeSize, .xxLarge)
            .previewDisplayName("Medium - XXL font")

        StoreInfoMetricsView(entryData: exampleData)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small")

        StoreInfoMetricsView(entryData: exampleData)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.dynamicTypeSize, .xxLarge)
            .previewDisplayName("Small - XXL font")
    }
}
#endif
