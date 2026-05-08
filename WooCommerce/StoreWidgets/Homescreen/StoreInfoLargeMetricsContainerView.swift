import SwiftUI

/// Renders the metrics layout used by the large home-screen widget family.
struct StoreInfoLargeMetricsContainerView: View {
    let data: StoreInfoData

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var visibleMetricSlots: [StoreInfoMetricSlot] {
        StoreInfoMetricSlotLayout.visibleSlots(
            from: data.metricSlots,
            family: .large,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.headerSpacing) {
            StoreInfoMetricsLogoHeader(data: data)

            StoreInfoMetricsGrid(metricSlots: visibleMetricSlots, leadingMetricStyle: .large)
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
            .environment(\.dynamicTypeSize, .xxLarge)
            .previewDisplayName("Large - XXL font")

        StoreInfoLargeMetricsContainerView(data: StoreInfoMetricsView_Previews.fullCatalogData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
            .previewDisplayName("Extra Large")
    }
}
#endif
