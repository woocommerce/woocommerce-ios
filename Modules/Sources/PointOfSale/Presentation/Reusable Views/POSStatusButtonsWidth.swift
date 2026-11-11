import SwiftUI

enum POSStatusButtonsLayout {
    static let maxWidth: CGFloat = 520
}

enum POSStatusButtonsWidth {
    case capped
    case fullWidth
}

private struct POSStatusButtonsWidthModifier: ViewModifier {
    @Environment(\.posMetrics) private var metrics
    @ScaledMetric private var maxWidth = POSStatusButtonsLayout.maxWidth

    let addsHorizontalPadding: Bool

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(maxWidth: maxWidth)
            .padding(.horizontal, addsHorizontalPadding ? metrics.padding.medium : metrics.padding.none)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func posStatusButtonsWidth(addsHorizontalPadding: Bool = true) -> some View {
        modifier(POSStatusButtonsWidthModifier(addsHorizontalPadding: addsHorizontalPadding))
    }
}
