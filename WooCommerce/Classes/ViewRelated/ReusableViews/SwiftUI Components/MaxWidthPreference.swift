import SwiftUI

/// PreferenceKey to store max value.
/// Used in `MaxWidthModifier` to calculate max title width among multiple fields/rows.
///
struct MaxWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        if let nv = nextValue(), nv > value ?? .zero {
            value = nv
        }
    }
}

/// Modifier to calculate view width and store it in `MaxWidthPreferenceKey`.
/// Used to calculate max frame and then align multiple fields/rows.
///
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
