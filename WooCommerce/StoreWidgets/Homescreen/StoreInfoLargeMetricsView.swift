import SwiftUI

/// Renders the metrics layout used by the large home-screen widget family.
struct StoreInfoLargeMetricsView: View {
    let data: StoreInfoData

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var visibleMetrics: [any MetricPresentable] {
        let limit = dynamicTypeSize > .xLarge ? Layout.accessibilityMetricLimit : Layout.defaultMetricLimit
        return Array(data.metrics.prefix(limit))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.headerSpacing) {
            headerView

            Spacer(minLength: Layout.metricSpacing)

            StoreInfoLargeMetricsCard(metrics: visibleMetrics)
        }
    }

    private var headerView: some View {
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
    }

    private enum Layout {
        static let noSpacing = 0.0
        static let headerSpacing = 12.0
        static let metricSpacing = 12.0
        static let logoSpacing = 4.0
        static let logoSize = 30.0
        static let defaultMetricLimit = 7
        static let accessibilityMetricLimit = 4
    }
}

/// Renders an ordered list of metrics in a 2-column grid for the large metrics layout.
private struct StoreInfoLargeMetricsCard: View {
    let metrics: [any MetricPresentable]

    /// Chunks metrics into rows for the large widget layout.
    /// Odd metric counts lead with a single full-width row so the remaining
    /// rows stay balanced in pairs: 7 metrics render as 1-2-2-2.
    ///
    private var rows: [[any MetricPresentable]] {
        guard !metrics.isEmpty else {
            return []
        }

        let firstRowCount = metrics.count.isMultiple(of: Layout.metricsPerRow) ? Layout.metricsPerRow : 1
        var rows = [Array(metrics.prefix(firstRowCount))]

        rows.append(contentsOf: stride(from: firstRowCount, to: metrics.count, by: Layout.metricsPerRow).map { start in
            Array(metrics[start..<min(start + Layout.metricsPerRow, metrics.count)])
        })

        return rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, metric in
                        MetricCellView(metric: metric)
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

// MARK: - Previews
#if DEBUG
import WidgetKit

struct StoreInfoLargeMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        StoreInfoLargeMetricsView(data: StoreInfoMetricsView_Previews.fullCatalogData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large")

        StoreInfoLargeMetricsView(data: StoreInfoMetricsView_Previews.fullCatalogData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .environment(\.dynamicTypeSize, .xxLarge)
            .previewDisplayName("Large - XXL font")

        StoreInfoLargeMetricsView(data: StoreInfoMetricsView_Previews.fullCatalogData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
            .previewDisplayName("Extra Large")
    }
}
#endif
