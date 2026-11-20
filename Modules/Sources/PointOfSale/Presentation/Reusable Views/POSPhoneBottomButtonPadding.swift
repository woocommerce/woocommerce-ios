import SwiftUI

private struct POSPhoneBottomButtonPaddingModifier: ViewModifier {
    @Environment(\.posMetrics) private var metrics

    let bottom: CGFloat?

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, metrics.padding.medium)
            .padding(.top, metrics.padding.medium)
            .padding(.bottom, bottom ?? metrics.padding.medium)
    }
}

extension View {
    /// Standard bottom-action padding for phone POS full-screen flows.
    func posPhoneBottomButtonPadding(bottom: CGFloat? = nil) -> some View {
        modifier(POSPhoneBottomButtonPaddingModifier(bottom: bottom))
    }
}

enum POSCompactFooterLayout {
    /// Match the compact page header's top spacing when there is no bottom inset.
    /// The system safe area supplies that space when its inset is larger.
    static func bottomPadding(safeAreaInset: CGFloat, metrics: POSMetrics) -> CGFloat {
        max(metrics.padding.medium - safeAreaInset, metrics.padding.none)
    }
}
