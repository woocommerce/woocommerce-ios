import SwiftUI

/// Renders the metrics layout used by the small home-screen widget family.
struct StoreInfoSmallMetricsView: View {
    let data: StoreInfoData

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
    }

    private enum Layout {
        static let noSpacing = 0.0
        static let headerSpacing = 6.0
        static let metricSpacing = 6.0
        static let logoSpacing = 4.0
        static let logoSize = 30.0
        static let defaultMetricLimit = 2
        static let accessibilityMetricLimit = 1
    }
}

// MARK: - Previews
#if DEBUG
import class WooFoundation.CurrencySettings
import WidgetKit

struct StoreInfoSmallMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        StoreInfoSmallMetricsView(data: StoreInfoMetricsView_Previews.exampleData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small")

        StoreInfoSmallMetricsView(data: StoreInfoMetricsView_Previews.exampleData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.dynamicTypeSize, .xxLarge)
            .previewDisplayName("Small - XXL font")
    }
}
#endif
