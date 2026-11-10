import StoreDesignSystem
import SwiftUI

struct StoreDashboardCustomizeButton: View {
    let showsNewCardsBadge: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        StoreButton(
            Localization.title,
            icon: StoreIcon.Pen.regular,
            variant: .tonal,
            action: action
        )
        .overlay(alignment: .topTrailing) {
            if showsNewCardsBadge && !isDisabled {
                Circle()
                    .fill(Color.storePrimary)
                    .frame(width: Layout.badgeSize, height: Layout.badgeSize)
                    .offset(Layout.badgeOffset)
            }
        }
        .disabled(isDisabled)
        .accessibilityIdentifier("dashboard-edit-button")
        .frame(maxWidth: .infinity)
    }
}

private extension StoreDashboardCustomizeButton {
    typealias Localization = DashboardCustomizationView.Localization

    enum Layout {
        static let badgeSize = StoreSpacing.s3
        static let badgeOffset = CGSize(width: StoreSpacing.s2, height: -StoreSpacing.s2)
    }
}
