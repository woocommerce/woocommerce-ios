import StoreDesignSystem
import SwiftUI

/// A More tab action rendered with Store Design System cell, icon, badge, and disclosure components.
struct StoreHubMenuRow: View {
    let item: HubMenuItem
    let onTap: (HubMenuItem) -> Void

    var body: some View {
        Group {
            if opensExternalDestination {
                StoreCell(
                    item.title,
                    description: item.description,
                    action: handleTap,
                    leading: StoreHubMenuIcon(item: item)
                ) {
                    StoreIcon.ArrowUpRight.regular.image(size: .medium)
                        .accessibilityHidden(true)
                }
            } else if case .dot = item.iconBadge {
                StoreCell(
                    item.title,
                    description: item.description,
                    action: handleTap,
                    leading: StoreHubMenuIcon(item: item)
                ) {
                    Circle()
                        .fill(Color.storePrimary)
                        .frame(width: StoreSpacing.s3, height: StoreSpacing.s3)
                        .accessibilityHidden(true)
                }
                .accessibilityValue(Localization.newFeature)
            } else {
                StoreCell(
                    item.title,
                    description: item.description,
                    action: handleTap,
                    leading: StoreHubMenuIcon(item: item)
                )
            }
        }
        .accessibilityIdentifier(item.accessibilityIdentifier)
    }

    private func handleTap() {
        onTap(item)
    }

    private var opensExternalDestination: Bool {
        item.id == HubMenuViewModel.WoocommerceAdmin.id || item.id == HubMenuViewModel.ViewStore.id
    }
}

private extension StoreHubMenuRow {
    enum Localization {
        static let newFeature = NSLocalizedString(
            "hubMenu.storeDesignSystem.newFeature",
            value: "New feature",
            comment: "VoiceOver value for a More menu item marked with a dot badge"
        )
    }
}
