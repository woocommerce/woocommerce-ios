import SwiftUI

/// Logo-led header shared by metric layouts that follow the small widget design.
struct StoreInfoMetricsLogoHeader: View {
    let data: StoreInfoData

    var body: some View {
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
    }

    private enum Layout {
        static let noSpacing = 0.0
        static let logoSpacing = 4.0
        static let logoSize = 30.0
    }
}
