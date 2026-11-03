import StoreDesignSystem
import SwiftUI

struct StoreDashboardNewCardsNotice: View {
    let showCustomization: () -> Void

    var body: some View {
        StoreDashboardCardSurface {
            VStack(spacing: StoreSpacing.s5) {
                VStack(spacing: StoreSpacing.s3) {
                    Text(Localization.title)
                        .storeTextStyle(.titleLarge.strong)
                    Text(Localization.subtitle)
                        .storeTextStyle(.bodyLarge)
                }
                .foregroundStyle(.storeOnSurface)
                .multilineTextAlignment(.center)

                StoreButton(Localization.action, action: showCustomization)
            }
            .padding(StorePadding.p5)
            .frame(maxWidth: .infinity)
        }
    }
}

private extension StoreDashboardNewCardsNotice {
    enum Localization {
        static let title = NSLocalizedString(
            "storeDashboardNewCardsNotice.title",
            value: "Looking for more insights?",
            comment: "Title of the card announcing new dashboard sections."
        )
        static let subtitle = NSLocalizedString(
            "storeDashboardNewCardsNotice.subtitle",
            value: "Add new sections to customize your store management experience",
            comment: "Description of the card announcing new dashboard sections."
        )
        static let action = NSLocalizedString(
            "storeDashboardNewCardsNotice.action",
            value: "Add New Sections",
            comment: "Button that opens dashboard customization to add new sections."
        )
    }
}
