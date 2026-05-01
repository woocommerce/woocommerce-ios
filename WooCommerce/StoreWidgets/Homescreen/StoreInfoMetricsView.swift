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
    @Environment(\.widgetFamily) private var family

    var accessibilityDynamicTypeSize: DynamicTypeSize {
        return .xLarge
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallView(data: entryData)
            case .systemMedium, .systemLarge, .systemExtraLarge:
                mediumView()
            default:
                let _ = assert(true, "This view only supports system families")
                EmptyView()
            }
        }
        .widgetBackground(backgroundView: Color(.brand))
    }

    private func mediumView() -> some View {
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
    }

    fileprivate enum Layout {
        static let sectionSpacing = 8.0
        static let cardSpacing = 2.0
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
}

/// View that renders widget for .systemSmall family
struct SmallView: View {
    let data: StoreInfoData

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var visibleMetrics: [any MetricPresentable] {
        let limit = dynamicTypeSize > .xLarge ? Layout.accessibilityMetricLimit : Layout.defaultMetricLimit
        return Array(data.metrics.prefix(limit))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.headerSpacing) {
            HStack(alignment: .top, spacing: Layout.noSpacing) {
                Image("woo-mini-logo", bundle: nil)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Layout.logoSize, height: Layout.logoSize)
                    .accessibilityHidden(true)

                Spacer(minLength: Layout.logoSpacing)

                VStack(alignment: .leading, spacing: Layout.noSpacing) {
                    Text(data.name)
                        .storeNameStyle()

                    Text(StoreInfoMetricsView.Localization.updatedAt(data.updatedTime))
                        .statRangeStyle()
                }
            }

            Spacer(minLength: Layout.metricSpacing)

            VStack(alignment: .leading, spacing: Layout.metricSpacing) {
                ForEach(Array(visibleMetrics.enumerated()), id: \.offset) { _, metric in
                    MetricCellView(metric: metric)
                }
            }
        }
        .padding(Layout.noSpacing)
    }

    private enum Layout {
        static let noSpacing = 0.0
        static let headerSpacing = 6.0
        static let metricSpacing = 6.0
        static let logoSpacing = 4.0
        static let logoSize = 30.0
        static let bigLogoSize = 50.0
        static let messageSpacing = 8.0
        static let defaultMetricLimit = 2
        static let accessibilityMetricLimit = 1
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
