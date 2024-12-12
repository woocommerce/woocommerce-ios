import SwiftUI

/// Applies a shadow to the bottom of the View component
///
struct POSBottomShadowViewModifier: ViewModifier {
    let backgroundColor: Color

    func body(content: Content) -> some View {
        content
            .background(
                backgroundColor
                    .shadow(color: Color(.secondarySystemFill), radius: 10, x: 0, y: 0)
                    .mask(Rectangle().padding(.bottom, -20))
            )
    }
}

extension View {
    func applyBottomShadow(backgroundColor: Color) -> some View {
        self.modifier(POSBottomShadowViewModifier(backgroundColor: backgroundColor))
    }
}
