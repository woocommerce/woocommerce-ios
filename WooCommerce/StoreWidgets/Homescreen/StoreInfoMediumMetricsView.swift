import SwiftUI

/// Renders the metrics layout used by medium and larger home-screen widget families.
struct StoreInfoMediumMetricsView: View {
    let data: StoreInfoData

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                HStack {
                    Text(data.name)
                        .storeNameStyle()
                    Spacer()
                    Text(data.range)
                        .statRangeStyle()
                }
                Text(StoreInfoMetricsView.Localization.updatedAt(data.updatedTime))
                    .statRangeStyle()
            }

            if dynamicTypeSize > Layout.accessibilityDynamicTypeSize {
                MetricsAccessibilityCard(entryData: data)
            } else {
                StoreInfoMetricsCard(metrics: data.metrics)
            }
        }
        .padding(.horizontal)
    }

    private enum Layout {
        static let sectionSpacing = 8.0
        static let cardSpacing = 2.0
        static let accessibilityDynamicTypeSize: DynamicTypeSize = .xLarge
    }
}

/// Renders an ordered list of metrics in a 2-column grid for the medium-style metrics layout.
/// Operates on the presentation protocol so the layout is decoupled from
/// the concrete `StoreInfoMetric` type.
///
private struct StoreInfoMetricsCard: View {
    let metrics: [any MetricPresentable]

    /// Chunks metrics into rows of two for the medium-style widget layout.
    ///
    private var rows: [[any MetricPresentable]] {
        stride(from: 0, to: metrics.count, by: Layout.metricsPerRow).map { start in
            Array(metrics[start..<min(start + Layout.metricsPerRow, metrics.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
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
        static let sectionSpacing = 8.0
        static let metricsPerRow = 2
    }
}

/// Accessibility card for metric widget layouts. Shows only revenue and a `View More` indicator.
///
private struct MetricsAccessibilityCard: View {
    let entryData: StoreInfoData

    var body: some View {
        let revenue = entryData.metric(of: .revenue)
        Group {
            VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                Text(revenue.title)
                    .statTitleStyle()

                Text(revenue.formattedValue)
                    .statValueStyle()
            }

            Text(StoreInfoMetricsView.Localization.viewMore)
                .statButtonStyle()
        }
    }

    private enum Layout {
        static let cardSpacing = 2.0
    }
}

// MARK: - Previews
#if DEBUG
import class WooFoundation.CurrencySettings
import WidgetKit

struct StoreInfoMediumMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        StoreInfoMediumMetricsView(data: StoreInfoMetricsView_Previews.exampleData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium")

        StoreInfoMediumMetricsView(data: StoreInfoMetricsView_Previews.exampleData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.dynamicTypeSize, .xxLarge)
            .previewDisplayName("Medium - XXL font")
    }
}
#endif
