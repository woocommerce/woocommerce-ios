import SwiftUI

/// Renders the metrics layout used by the large home-screen widget family.
struct StoreInfoLargeMetricsContainerView: View {
    let data: StoreInfoData

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var visibleMetrics: [any MetricPresentable] {
        let limit = dynamicTypeSize > .xLarge ? Layout.accessibilityMetricLimit : Layout.defaultMetricLimit
        return Array(data.metrics.prefix(limit))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.headerSpacing) {
            StoreInfoMetricsLogoHeader(data: data)

            Spacer(minLength: Layout.metricSpacing)

            StoreInfoMetricsGrid(metrics: visibleMetrics, leadingMetricStyle: .large)
        }
    }

    private enum Layout {
        static let headerSpacing = 12.0
        static let metricSpacing = 12.0
        static let defaultMetricLimit = 7
        static let accessibilityMetricLimit = 4
    }
}

// MARK: - Previews
#if DEBUG
import WidgetKit

struct StoreInfoLargeMetricsContainerView_Previews: PreviewProvider {
    static var previews: some View {
        StoreInfoLargeMetricsContainerView(data: StoreInfoMetricsView_Previews.fullCatalogData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large")

        StoreInfoLargeMetricsContainerView(data: StoreInfoMetricsView_Previews.fullCatalogData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .environment(\.dynamicTypeSize, .xxLarge)
            .previewDisplayName("Large - XXL font")

        StoreInfoLargeMetricsContainerView(data: StoreInfoMetricsView_Previews.fullCatalogData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
            .previewDisplayName("Extra Large")
    }
}
#endif
