import SwiftUI

/// Renders the metrics layout used by the small home-screen widget family.
struct StoreInfoSmallMetricsContainerView: View {
    let data: StoreInfoData

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var visibleMetrics: [any MetricPresentable] {
        let limit = StoreInfoDynamicType.usesAccessibilityLayout(dynamicTypeSize) ? Layout.accessibilityMetricLimit : Layout.defaultMetricLimit
        return Array(data.metrics.prefix(limit))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.headerSpacing) {
            StoreInfoMetricsLogoHeader(data: data, showsRange: false)

            Spacer(minLength: Layout.metricSpacing)

            VStack(alignment: .leading, spacing: Layout.metricSpacing) {
                ForEach(Array(visibleMetrics.enumerated()), id: \.offset) { _, metric in
                    MetricCellView(metric: metric)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private enum Layout {
        static let headerSpacing = 6.0
        static let metricSpacing = 6.0
        static let defaultMetricLimit = 2
        static let accessibilityMetricLimit = 1
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
