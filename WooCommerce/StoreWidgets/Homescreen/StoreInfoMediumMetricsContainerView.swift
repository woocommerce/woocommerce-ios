import SwiftUI

/// Renders the metrics layout used by the medium home-screen widget family.
struct StoreInfoMediumMetricsContainerView: View {
    let data: StoreInfoData

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var visibleMetricSlots: [StoreInfoMetricSlot] {
        StoreInfoMetricSlotLayout.visibleSlots(
            from: data.metricSlots,
            family: .medium,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            StoreInfoMetricsLogoHeader(data: data)

            StoreInfoMetricsGrid(metricSlots: visibleMetricSlots)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private enum Layout {
        static let sectionSpacing = 8.0
    }
}

// MARK: - Previews
#if DEBUG
import class WooFoundation.CurrencySettings
import WidgetKit

struct StoreInfoMediumMetricsContainerView_Previews: PreviewProvider {
    static var previews: some View {
        StoreInfoMediumMetricsContainerView(data: StoreInfoMetricsView_Previews.exampleData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium")

        StoreInfoMediumMetricsContainerView(data: StoreInfoMetricsView_Previews.exampleData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.dynamicTypeSize, .accessibility1)
            .previewDisplayName("Medium - Accessibility font")
    }
}
#endif
