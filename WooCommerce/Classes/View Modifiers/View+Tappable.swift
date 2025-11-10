import SwiftUI

private struct TappableViewModifier: ViewModifier {
    let onTap: () -> Void

    func body(content: Content) -> some View {
        Button {
            onTap()
        } label: {
            content
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func tappable(_ onTap: @escaping () -> Void) -> some View {
        self.modifier(TappableViewModifier(onTap: onTap))
    }
}
