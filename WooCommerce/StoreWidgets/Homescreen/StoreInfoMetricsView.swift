import SwiftUI
import WidgetKit

/// Medium home-screen widget view driven by the metric catalog.
///
/// Companion to the legacy `StoreInfoView`; both render the same widget family but consume
/// different shapes off `StoreInfoData`. Selection happens in `StoreInfoHomescreenWidget`
/// based on `useMetricsHomescreenWidget`.
///
struct StoreInfoMetricsView: View {
    let entryData: StoreInfoData

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var accessibilityDynamicTypeSize: DynamicTypeSize {
        return .xLarge
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                HStack {
                    Text(entryData.name)
                        .storeNameStyle()
                    Spacer()
                    Text(entryData.range)
                        .statRangeStyle()
                }
                Text(Localization.updatedAt(entryData.updatedTime))
                    .statRangeStyle()
            }

            if dynamicTypeSize > accessibilityDynamicTypeSize {
                MetricsAccessibilityCard(entryData: entryData)
            } else {
                StoreInfoMetricsCard(metrics: entryData.metrics)
            }
        }
        .padding(.horizontal)
        .widgetBackground(backgroundView: Color(.brand))
    }
}

/// Renders an ordered list of metrics in a 2-column grid for the medium widget.
/// Operates on the presentation protocol so the layout is decoupled from
/// the concrete `StoreInfoMetric` type.
///
struct StoreInfoMetricsCard: View {
    let metrics: [any MetricPresentable]

    /// Chunks metrics into rows of two for the medium widget layout.
    ///
    private var rows: [[any MetricPresentable]] {
        stride(from: 0, to: metrics.count, by: Layout.metricsPerRow).map { start in
            Array(metrics[start..<min(start + Layout.metricsPerRow, metrics.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StoreInfoMetricsView.Layout.sectionSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, metric in
                        MetricCellView(metric: metric)
                    }
                    // Pad the last row so a trailing cell keeps the grid alignment
                    // when the row has fewer metrics than the slot count.
                    if row.count < Layout.metricsPerRow {
                        ForEach(0..<(Layout.metricsPerRow - row.count), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private enum Layout {
        static let metricsPerRow = 2
    }
}

/// Accessibility card for `StoreInfoMetricsView`. Shows only revenue and a `View More` button.
///
private struct MetricsAccessibilityCard: View {
    let entryData: StoreInfoData

    var body: some View {
        let revenue = entryData.metric(of: .revenue)
        Group {
            VStack(alignment: .leading, spacing: StoreInfoMetricsView.Layout.cardSpacing) {
                Text(revenue.title)
                    .statTitleStyle()

                Text(revenue.formattedValue)
                    .statValueStyle()
            }

            Text(StoreInfoMetricsView.Localization.viewMore)
                .statButtonStyle()
        }
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

    enum Layout {
        static let sectionSpacing = 8.0
        static let cardSpacing = 2.0
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

        StoreInfoMetricsView(entryData: exampleData)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.dynamicTypeSize, .xxLarge)
            .previewDisplayName("XXL font")
    }
}
#endif
