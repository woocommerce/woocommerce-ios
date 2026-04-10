import SwiftUI

private enum Layout {
    static let color: Color = .gray.opacity(0.3)
    static let width: CGFloat = 0.5
}

struct VerticalHairlineBorders: ViewModifier {

    func body(content: Content) -> some View {
        content
            .overlay(
                HStack {
                    Rectangle()
                        .fill(Layout.color)
                        .frame(width: Layout.width)
                    Spacer()
                    Rectangle()
                        .fill(Layout.color)
                        .frame(width: Layout.width)
                }
            )
    }
}

extension View {
    func verticalHairlineBorders() -> some View {
        self.modifier(VerticalHairlineBorders())
    }
}
