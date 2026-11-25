import SwiftUI

private struct POSBottomButtonPaddingModifier: ViewModifier {
    @Environment(\.posMetrics) private var metrics

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, metrics.padding.medium)
            .padding(.top, metrics.padding.medium)
            .posFooterBottomPadding()
    }
}

/// Puts bottom buttons on the bottom safe-area edge, or `medium` above the bottom when there is no inset.
/// A full-size keyboard keeps `medium` so the buttons do not touch it.
private struct POSFooterBottomPaddingModifier: ViewModifier {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.keyboardObserver) private var keyboard

    @State private var bottomSafeAreaInset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .padding(.bottom, bottomPadding)
            .onGeometryChange(for: CGFloat.self, of: { $0.safeAreaInsets.bottom }) { bottomSafeAreaInset = $0 }
    }

    private var bottomPadding: CGFloat {
        guard !keyboard.isFullSizeKeyboardVisible else {
            return metrics.padding.medium
        }
        return max(metrics.padding.medium - bottomSafeAreaInset, metrics.padding.none)
    }
}

extension View {
    /// Standard padding for bottom actions in POS full-screen flows.
    func posBottomButtonPadding() -> some View {
        modifier(POSBottomButtonPaddingModifier())
    }

    func posFooterBottomPadding() -> some View {
        modifier(POSFooterBottomPaddingModifier())
    }
}
