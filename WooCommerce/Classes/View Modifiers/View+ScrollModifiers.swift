import SwiftUI

/// View modifier that conditionally wraps the `content` in a `Scrollview` if the `content` height exceeds the view height.
///
struct ConditionalVerticalScrollModifier: ViewModifier {

    /// Keeps track of the `content` rendered size
    ///
    @State private var contentSize: CGSize = .zero

    /// Defines if the content should scroll or not.
    ///
    @State private var shouldScroll: Bool = false


    func body(content: Content) -> some View {
        GeometryReader { parentGeometry in
            if shouldScroll {
                ScrollView(.vertical, showsIndicators: false) {
                    contentGeometryListener(content: content, parentGeometry: parentGeometry)
                }
            } else {
                contentGeometryListener(content: content, parentGeometry: parentGeometry)
            }
        }
        .frame(maxHeight: contentSize.height)
    }

    /// Updates the `contentSize` property by adding a clear background to the `content` that has a `GeometryReader` attached to it.
    /// Updates the `shouldScroll` property when the content vertical geometry is greater than the parent vertical geometry.
    ///
    private func contentGeometryListener(content: Content, parentGeometry: GeometryProxy) -> some View {
        content
            .background(
                GeometryReader { contentGeometry -> Color in
                    DispatchQueue.main.async {
                        contentSize = contentGeometry.size
                        shouldScroll = contentGeometry.size.height > parentGeometry.size.height
                    }
                    return .clear
                }
            )
    }
}

// MARK: View Extensions

extension View {
    /// Allows the view to scroll vertically when the content height is greater than it's parent height.
    ///
    func scrollVerticallyIfNeeded() -> some View {
        self.modifier(ConditionalVerticalScrollModifier())
    }
}
