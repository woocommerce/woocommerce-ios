import SwiftUI

/// Applies a shadow to the bottom of the View component
///
struct POSBottomShadowViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
            Color.white
                .shadow(color: Color(.secondarySystemFill), radius: 10, x: 0, y: 0)
                .mask(Rectangle().padding(.bottom, -20))
        )
    }
}

extension View {
    func applyBottomShadow() -> some View {
        self.modifier(POSBottomShadowViewModifier())
    }
}
