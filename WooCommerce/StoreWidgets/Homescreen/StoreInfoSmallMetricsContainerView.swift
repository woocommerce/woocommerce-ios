import SwiftUI

/// Renders the metrics layout used by the small home-screen widget family.
struct StoreInfoSmallMetricsContainerView: View {
    let data: StoreInfoData

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var visibleMetricSlots: [StoreInfoMetricSlot] {
        StoreInfoMetricSlotLayout.visibleSlots(
            from: data.metricSlots,
            family: .small,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    private var showsUpdatePrefix: Bool {
        !StoreInfoDynamicType.usesCondensedLayout(dynamicTypeSize)
    }

    private var showsUpdatedTime: Bool {
        !StoreInfoDynamicType.usesCondensedLayout(dynamicTypeSize)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.headerSpacing(for: dynamicTypeSize)) {
            StoreInfoMetricsLogoHeader(data: data,
                                       showsRange: false,
                                       showsUpdatePrefix: showsUpdatePrefix,
                                       showsUpdatedTime: showsUpdatedTime)

            Spacer(minLength: Layout.metricSpacing(for: dynamicTypeSize))

            VStack(alignment: .leading, spacing: Layout.metricSpacing(for: dynamicTypeSize)) {
                ForEach(Array(visibleMetricSlots.enumerated()), id: \.offset) { _, slot in
                    MetricSlotView(slot: slot, placeholderMinHeight: Layout.emptyMetricMinHeight) { metric in
                        MetricCellView(metric: WidgetMetricPresenter(metric: metric, dateRange: data.dateRange))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private enum Layout {
        static func headerSpacing(for dynamicTypeSize: DynamicTypeSize) -> Double {
            StoreInfoDynamicType.usesCondensedLayout(dynamicTypeSize) ? 4.0 : 6.0
        }

        static func metricSpacing(for dynamicTypeSize: DynamicTypeSize) -> Double {
            StoreInfoDynamicType.usesCondensedLayout(dynamicTypeSize) ? 4.0 : 6.0
        }

        static let emptyMetricMinHeight = 36.0
    }
}

// MARK: - Previews
#if DEBUG
import class WooFoundation.CurrencySettings
import WidgetKit

struct StoreInfoSmallMetricsContainerView_Previews: PreviewProvider {
    static var previews: some View {
        StoreInfoSmallMetricsContainerView(data: StoreInfoMetricsView_Previews.exampleData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small")

        StoreInfoSmallMetricsContainerView(data: StoreInfoMetricsView_Previews.exampleData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.dynamicTypeSize, .accessibility1)
            .previewDisplayName("Small - Accessibility font")
    }
}
#endif
