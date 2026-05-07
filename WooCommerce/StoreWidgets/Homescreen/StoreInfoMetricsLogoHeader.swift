import SwiftUI

/// Logo-led header shared by all metric layouts.
struct StoreInfoMetricsLogoHeader: View {
    let data: StoreInfoData
    private let showsRange: Bool

    init(data: StoreInfoData, showsRange: Bool = true) {
        self.data = data
        self.showsRange = showsRange
    }

    var body: some View {
        HStack(alignment: .top, spacing: Layout.logoSpacing) {
            Image("woo-mini-logo", bundle: nil)
                .resizable()
                .scaledToFit()
                .frame(width: Layout.logoSize, height: Layout.logoSize)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Layout.textSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: Layout.rangeSpacing) {
                    Text(data.name)
                        .storeNameStyle()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    if showsRange {
                        Spacer(minLength: Layout.rangeSpacing)

                        Text(data.range)
                            .statRangeStyle()
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }

                Text(StoreInfoMetricsView.Localization.updatedAt(data.updatedTime))
                    .statRangeStyle()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private enum Layout {
        static let logoSpacing = 12.0
        static let logoSize = 30.0
        static let rangeSpacing = 4.0
        static let textSpacing = 0.0
    }
}

// MARK: - Previews
#if DEBUG
import WidgetKit

struct StoreInfoMetricsLogoHeader_Previews: PreviewProvider {
    static var previews: some View {
        StoreInfoMetricsLogoHeader(data: StoreInfoMetricsView_Previews.exampleData)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("With range")

        StoreInfoMetricsLogoHeader(data: StoreInfoMetricsView_Previews.exampleData, showsRange: false)
            .widgetBackground(backgroundView: Color(.brand))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Without range")
    }
}
#endif
