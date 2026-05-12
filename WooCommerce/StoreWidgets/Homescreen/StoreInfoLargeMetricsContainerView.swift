import SwiftUI

/// Renders the metrics layout used by the large home-screen widget family.
struct StoreInfoLargeMetricsContainerView: View {
    let data: StoreInfoData

    private var presentableMetrics: [any MetricPresentable] {
        data.metrics.map { metric in
            WidgetMetricPresenter(metric: metric, dateRange: data.dateRange)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.headerSpacing) {
            StoreInfoMetricsLogoHeader(data: data)

            StoreInfoMetricsGrid(metrics: presentableMetrics, leadingMetricStyle: .large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private enum Layout {
        static let headerSpacing = 12.0
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
            .environment(\.dynamicTypeSize, .accessibility1)
            .previewDisplayName("Large - Accessibility font")

        StoreInfoLargeMetricsContainerView(data: StoreInfoMetricsView_Previews.fullCatalogData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
            .previewDisplayName("Extra Large")
    }
}
#endif
