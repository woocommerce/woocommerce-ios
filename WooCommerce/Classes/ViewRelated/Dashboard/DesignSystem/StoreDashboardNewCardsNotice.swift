import StoreDesignSystem
import SwiftUI

struct StoreDashboardNewCardsNotice: View {
    let showCustomization: () -> Void

    var body: some View {
        StoreDashboardCardSurface {
            VStack(spacing: StoreSpacing.s5) {
                VStack(spacing: StoreSpacing.s3) {
                    Text(Localization.title)
                        .storeTextStyle(.titleMedium.emphasized)
                    Text(Localization.subtitle)
                        .storeTextStyle(.bodyMedium)
                }
                .foregroundStyle(.storeOnSurface)
                .multilineTextAlignment(.center)

                StoreButton(Localization.addSectionsButtonText, action: showCustomization)
            }
            .padding(StorePadding.p5)
            .frame(maxWidth: .infinity)
        }
    }
}

private extension StoreDashboardNewCardsNotice {
    typealias Localization = DashboardView.Localization.NewCardsNoticeCard
}

#Preview("Feedback") {
    StoreDashboardNewCardsNotice(showCustomization: {})
        .padding(StorePadding.p5)
        .background(Color.storeSurfaceDim)
}
