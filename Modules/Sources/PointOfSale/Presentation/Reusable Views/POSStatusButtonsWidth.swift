import SwiftUI

enum POSStatusButtonsLayout {
    /// One button width for every POS status, empty and error screen. Narrower containers (phone) get the full width.
    static let maxWidth: CGFloat = 520
}

private struct POSStatusButtonsWidthModifier: ViewModifier {
    @Environment(\.posMetrics) private var metrics

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(maxWidth: POSStatusButtonsLayout.maxWidth)
            .padding(.horizontal, metrics.padding.medium)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    /// Width of the buttons on POS status, empty and error screens: a centered column of
    /// `POSStatusButtonsLayout.maxWidth`, full width when the container is narrower.
    func posStatusButtonsWidth() -> some View {
        modifier(POSStatusButtonsWidthModifier())
    }
}
