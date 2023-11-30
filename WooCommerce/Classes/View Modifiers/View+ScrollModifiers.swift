import SwiftUI

/// Preference key for communicating sizes
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize? = nil

    static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
        // Take the response of the first child which updates the key. Disallow further updates from its children.
        value = value ?? nextValue()
    }
}

/// View modifier that conditionally wraps the `content` in a `ScrollView` if the `content` height exceeds the view height.
///
struct ConditionalVerticalScrollModifier: ViewModifier {
    /// Defines if the content should scroll or not.
    @State private var shouldScroll: Bool = false

    func body(content: Content) -> some View {
        GeometryReader { parentGeometry in
            Group {
                if shouldScroll {
                    ScrollView(.vertical, showsIndicators: false) {
                        contentGeometryListener(content: content)
                    }
                } else {
                    contentGeometryListener(content: content)
                }
            }
            .onPreferenceChange(SizePreferenceKey.self) { contentSize in
                /// Using `onPreferenceChange` avoid changing state (`shouldScroll`) during a layout pass.
                /// Changing state that's used to layout the view during layout can cause an infinite loop and make the screen unresponsive.
                if let contentSize = contentSize {
                    shouldScroll = contentSize.height > parentGeometry.size.height
                }
            }
        }
    }

    /// Updates the `SizePreferenceKey` by adding a clear background to the `content` that has a `GeometryReader` attached to it.
    /// This is used in the parent to update the `shouldScroll` property when the content vertical geometry is greater than the parent vertical geometry.
    ///
    private func contentGeometryListener(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: geometry.size)
                })
    }
}

// MARK: View Extensions

extension View {
    /// Allows the view to scroll vertically when the content height is greater than its parent height.
    ///
    func scrollVerticallyIfNeeded() -> some View {
        self.modifier(ConditionalVerticalScrollModifier())
    }
}
