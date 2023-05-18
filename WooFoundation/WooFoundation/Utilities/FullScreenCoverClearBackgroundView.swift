import SwiftUI

/// Use this view to clear the background of a view in SwiftUI after it's presented with `fullScreenCover`
///
/// Use it as follows:
///
///```
/// .fullScreenCover(isPresented: $showingFooView) {
///     FooView()
///    .background(FullScreenCoverClearBackgroundView())
/// }
/// ```
///
public struct FullScreenCoverClearBackgroundView: UIViewRepresentable {
    public init() {}

    public func makeUIView(context: Context) -> UIView {
        return InnerView()
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
    }

    private class InnerView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()

            superview?.superview?.backgroundColor = .clear
        }
    }
}
