import StoreDesignSystem
import SwiftUI

struct StoreTopPerformersEmptyView: View {
    var body: some View {
        VStack(spacing: StoreSpacing.s7) {
            Image(uiImage: .magnifyingGlassNotFoundGrey)
                .accessibilityHidden(true)
            Text(Localization.text)
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(.storeOnSurface)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, StorePadding.p8)
        .padding(.bottom, StorePadding.p7)
        .padding(.horizontal, StorePadding.p5)
    }
}

private extension StoreTopPerformersEmptyView {
    enum Localization {
        static let text = NSLocalizedString(
            "No activity this period",
            comment: "Default text for Top Performers section when no data exists for a given period."
        )
    }
}
