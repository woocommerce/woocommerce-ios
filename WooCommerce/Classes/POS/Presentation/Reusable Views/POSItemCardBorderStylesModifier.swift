import SwiftUI

struct POSItemCardBorderStylesModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
                    .stroke(Color.black, lineWidth: Constants.nilOutline)
            }
            .clipShape(RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
    }
}

private extension POSItemCardBorderStylesModifier {
    enum Constants {
        static let cardCornerRadius: CGFloat = 8.0
        // The use of stroke means the shape is rendered as an outline (border) rather than a filled shape,
        // since we still have to give it a value, we use 0 so it renders no border but it's shaped as one.
        static let nilOutline: CGFloat = 0
    }
}

extension View {
    /// Applies the POS item card border styles to the view.
    func posItemCardBorderStyles() -> some View {
        self.modifier(POSItemCardBorderStylesModifier())
    }
}
