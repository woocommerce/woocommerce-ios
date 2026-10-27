import StoreDesignSystem
import SwiftUI

struct StoreDashboardUnavailableAnalyticsView: View {
    private let title: String

    init(title: String) {
        self.title = title
    }

    var body: some View {
        HStack(alignment: .top, spacing: StoreSpacing.s4) {
            StoreIcon.CircleInfo.regular.image(size: .medium)
                .foregroundStyle(.storeOnSurfaceVariant)
                .accessibilityHidden(true)

            Text(title)
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(.storeOnSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(StorePadding.p7)
        .background(Color.storeSectionBackground)
        .clipShape(.rect(cornerRadius: StoreRadius.large))
        .padding(.horizontal, StorePadding.p7)
    }
}
