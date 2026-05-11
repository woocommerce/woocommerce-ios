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

            if StoreInfoMetricSlotLayout.usesAccessibilityLayout(dynamicTypeSize: dynamicTypeSize) {
                StoreInfoMetricsAccessibilitySummaryView(metricSlots: visibleMetricSlots)
            } else {
                StoreInfoMetricsGrid(metricSlots: visibleMetricSlots)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private enum Layout {
        static let sectionSpacing = 8.0
    }
}

/// Accessibility summary for metric widget layouts. Shows the first configured slot and a `View More` indicator.
///
private struct StoreInfoMetricsAccessibilitySummaryView: View {
    let metricSlots: [StoreInfoMetricSlot]

    var body: some View {
        Group {
            if let firstSlot = metricSlots.first {
                MetricSlotView(slot: firstSlot, placeholderMinHeight: Layout.emptyMetricMinHeight) { metric in
                    VStack(alignment: .leading, spacing: Layout.cardSpacing) {
                        Text(metric.title)
                            .statTitleStyle()

                        Text(metric.formattedValue)
                            .statValueStyle()
                    }
                }
            }

            Text(StoreInfoMetricsView.Localization.viewMore)
                .statButtonStyle()
        }
    }

    private enum Layout {
        static let cardSpacing = 2.0
        static let emptyMetricMinHeight = 36.0
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
