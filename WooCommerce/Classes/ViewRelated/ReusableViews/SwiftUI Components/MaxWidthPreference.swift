import SwiftUI

struct MaxWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        if let nv = nextValue(), nv > value ?? .zero {
            value = nv
        }
    }
}

struct MaxWidthModifier: ViewModifier {
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: MaxWidthPreferenceKey.self,
                            value: geometry.size.width)
        }
    }

    func body(content: Content) -> some View {
        content.background(sizeView)
    }
}
