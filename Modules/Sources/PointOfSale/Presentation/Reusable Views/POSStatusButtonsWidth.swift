import SwiftUI

enum POSStatusButtonsLayout {
    static let maxWidth: CGFloat = 520
}

private struct POSStatusButtonsWidthModifier: ViewModifier {
    @Environment(\.posMetrics) private var metrics

    let addsHorizontalPadding: Bool

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(maxWidth: POSStatusButtonsLayout.maxWidth)
            .padding(.horizontal, addsHorizontalPadding ? metrics.padding.medium : metrics.padding.none)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func posStatusButtonsWidth(addsHorizontalPadding: Bool = true) -> some View {
        modifier(POSStatusButtonsWidthModifier(addsHorizontalPadding: addsHorizontalPadding))
    }
}
