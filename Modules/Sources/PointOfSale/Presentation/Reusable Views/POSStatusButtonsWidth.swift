import SwiftUI

private struct POSStatusButtonsWidthModifier: ViewModifier {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.posLayoutScale) private var layoutScale

    let regularWidth: CGFloat?

    func body(content: Content) -> some View {
        if layoutScale == .compact {
            content
                .frame(maxWidth: .infinity)
                .padding(.horizontal, metrics.padding.medium)
        } else {
            content
                .frame(width: regularWidth)
        }
    }
}

extension View {
    /// Width of the buttons on POS status, empty and error screens.
    /// Compact layout: the buttons fill the width. Regular layout: `regularWidth`.
    func posStatusButtonsWidth(regularWidth: CGFloat?) -> some View {
        modifier(POSStatusButtonsWidthModifier(regularWidth: regularWidth))
    }
}
