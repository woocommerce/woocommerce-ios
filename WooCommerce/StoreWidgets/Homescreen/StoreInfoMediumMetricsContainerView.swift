import SwiftUI

/// Renders the metrics layout used by the medium home-screen widget family.
struct StoreInfoMediumMetricsContainerView: View {
    let data: StoreInfoData

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            StoreInfoMetricsLogoHeader(data: data)

            if dynamicTypeSize > Layout.accessibilityDynamicTypeSize {
                StoreInfoMetricsAccessibilitySummaryView(entryData: data)
            } else {
                StoreInfoMetricsGrid(metrics: data.metrics)
            }
        }
        .padding(.horizontal)
    }

    private enum Layout {
        static let sectionSpacing = 8.0
        static let accessibilityDynamicTypeSize: DynamicTypeSize = .xLarge
    }
}

/// Accessibility summary for metric widget layouts. Shows only revenue and a `View More` indicator.
///
private struct StoreInfoMetricsAccessibilitySummaryView: View {
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

struct StoreInfoMediumMetricsContainerView_Previews: PreviewProvider {
    static var previews: some View {
        StoreInfoMediumMetricsContainerView(data: StoreInfoMetricsView_Previews.exampleData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium")

        StoreInfoMediumMetricsContainerView(data: StoreInfoMetricsView_Previews.exampleData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.dynamicTypeSize, .xxLarge)
            .previewDisplayName("Medium - XXL font")
    }
}
#endif
