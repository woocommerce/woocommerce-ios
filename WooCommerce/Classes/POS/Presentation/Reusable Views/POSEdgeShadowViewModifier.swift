import SwiftUI

/// Applies a shadow to an edge of the View component
/// Note that this uses the POSShadow definition, which has vertically offset shadows.
/// Shadows at the top edge of a view will be less prominent than those at the bottom or leading/trailing.
///
struct POSEdgeShadowViewModifier: ViewModifier {
    let backgroundColor: Color
    let edges: Edge.Set

    func body(content: Content) -> some View {
        content
            .background(
                backgroundColor
                    .posShadow(.medium)
                    .mask(Rectangle().padding(edges, -20))
            )
    }
}

extension View {
    func applyEdgeShadow(backgroundColor: Color, edges: Edge.Set) -> some View {
        self.modifier(POSEdgeShadowViewModifier(backgroundColor: backgroundColor, edges: edges))
    }
}
