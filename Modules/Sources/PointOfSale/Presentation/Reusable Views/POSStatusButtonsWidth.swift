import SwiftUI

enum POSStatusButtonsLayout {
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
    func posStatusButtonsWidth() -> some View {
        modifier(POSStatusButtonsWidthModifier())
    }
}
