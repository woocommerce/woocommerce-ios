import StoreDesignSystem
import SwiftUI

/// Load error banner of the design-system Orders and Products lists; tapping it collapses or expands it.
struct StoreOrderListErrorBanner: View {
    let title: String
    let message: String
    let isExpanded: Bool
    let onToggle: () -> Void
    let onTroubleshoot: () -> Void
    let onContactSupport: () -> Void

    var body: some View {
        StoreNoticeBanner(title,
                          description: isExpanded ? message : nil,
                          tone: .error,
                          icon: StoreIcon.CircleInfo.regular,
                          actionTitle: isExpanded ? ErrorTopBannerFactory.Localization.contactSupport : nil,
                          action: isExpanded ? onContactSupport : nil,
                          prominentActionTitle: isExpanded ? ErrorTopBannerFactory.Localization.troubleshoot : nil,
                          prominentAction: isExpanded ? onTroubleshoot : nil,
                          accessibilityStatus: OrderListLocalization.errorAccessibilityStatus)
            .contentShape(Rectangle())
            .onTapGesture(perform: onToggle)
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(isExpanded ? OrderListLocalization.expandedAccessibilityValue : OrderListLocalization.collapsedAccessibilityValue)
            .accessibilityHint(isExpanded ? OrderListLocalization.collapseAccessibilityHint : OrderListLocalization.expandAccessibilityHint)
            .accessibilityAction {
                onToggle()
            }
    }
}
