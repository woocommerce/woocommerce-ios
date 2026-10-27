import SwiftUI

/// Use this view to make a sheet with detents reachable by VoiceOver when it's presented over a full-screen presentation.
/// UIKit keeps the full-screen presentation as the accessibility modal view, so the sheet is left out of the accessibility tree.
/// While the sheet is on screen, this view hides everything behind it from accessibility instead.
///
/// Use it as follows:
///
///```
/// .sheet(isPresented: $showingFooView) {
///     FooView()
///         .presentationDetents([.medium])
///         .background(SheetAccessibilityModalView())
/// }
/// ```
///
public struct SheetAccessibilityModalView: UIViewRepresentable {
    public init() {}

    public func makeUIView(context: Context) -> UIView {
        return InnerView()
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
    }

    private class InnerView: UIView {
        private var hiddenViews: [(view: UIView, elementsHidden: Bool, viewIsModal: Bool)] = []

        override func didMoveToWindow() {
            super.didMoveToWindow()

            restoreHiddenViews()
            if let window {
                hideViewsBehindSheet(in: window)
            }
        }

        private func hideViewsBehindSheet(in window: UIWindow) {
            var sheetContainer: UIView = self
            while let superview = sheetContainer.superview, superview !== window {
                sheetContainer = superview
            }
            guard let sheetIndex = window.subviews.firstIndex(of: sheetContainer) else {
                return
            }
            for view in window.subviews[..<sheetIndex] {
                hiddenViews.append((view, view.accessibilityElementsHidden, view.accessibilityViewIsModal))
                view.accessibilityViewIsModal = false
                view.accessibilityElementsHidden = true
            }
        }

        private func restoreHiddenViews() {
            for hiddenView in hiddenViews {
                hiddenView.view.accessibilityElementsHidden = hiddenView.elementsHidden
                hiddenView.view.accessibilityViewIsModal = hiddenView.viewIsModal
            }
            hiddenViews = []
        }
    }
}
