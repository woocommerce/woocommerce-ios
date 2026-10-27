import StoreDesignSystem
import SwiftUI

struct StoreDashboardCardOverflowMenu<Actions: View>: View {
    private let isDisabled: Bool
    private let actions: Actions

    init(isDisabled: Bool = false, @ViewBuilder actions: () -> Actions) {
        self.isDisabled = isDisabled
        self.actions = actions()
    }

    var body: some View {
        Menu {
            actions
        } label: {
            StoreIcon.Ellipsis.regular.image(size: .medium)
                .foregroundStyle(.storeOnSurfaceVariant)
                .frame(minWidth: StoreDashboardCardOverflowMenuConstants.minimumTapTarget,
                       minHeight: StoreDashboardCardOverflowMenuConstants.minimumTapTarget)
                .contentShape(.rect)
        }
        .disabled(isDisabled)
        .accessibilityLabel(StoreDashboardCardOverflowMenuLocalization.accessibilityLabel)
    }
}

private enum StoreDashboardCardOverflowMenuConstants {
    static let minimumTapTarget: CGFloat = 44
}

private enum StoreDashboardCardOverflowMenuLocalization {
    static let accessibilityLabel = NSLocalizedString(
        "More options",
        comment: "Accessibility label for an overflow menu."
    )
}
