import SwiftUI

/// `SwiftUI` wrapper adding a "discard changes" prompt on the dismiss drag gesture for the provided view.
///
struct DiscardChangesWrapper<Content: View>: UIViewControllerRepresentable {
    let view: Content

    /// Method that creates and presents a discard changes action sheet.
    ///
    /// Can inject a method from `UIAlertController+Helpers` or a custom action sheet, as needed.
    ///
    let presentActionSheet: (UIViewController) -> Void

    /// Whether the view can be dismissed. When `false` the discard changes prompt is displayed.
    ///
    let canDismiss: Bool

    /// Optional method to be invoked when the view is dismissed.
    ///
    let didDismiss: (() -> Void)?

    typealias UIViewControllerType = UIHostingController<Content>

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let viewController = UIHostingController(rootView: view)
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        context.coordinator.wrapper = self
        uiViewController.parent?.presentationController?.delegate = context.coordinator
    }

    func makeCoordinator() -> Self.Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var wrapper: DiscardChangesWrapper

        init(_ wrapper: DiscardChangesWrapper) {
            self.wrapper = wrapper
        }

        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            wrapper.canDismiss
        }

        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            wrapper.presentActionSheet(presentationController.presentedViewController)
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            wrapper.didDismiss?()
        }
    }
}

extension View {
    /// Adds a discard changes prompt on the dismiss drag gesture for the provided view.
    /// - Parameters:
    ///   - presentActionSheet: Method that creates and presents a discard changes action sheet.
    ///   - canDismiss: Whether the view can be dismissed. When `false` the discard changes prompt is displayed.
    ///   - didDismiss: Optional method to be invoked when the view is dismissed.
    func discardChangesPrompt(presentActionSheet: @escaping (UIViewController) -> Void,
                              canDismiss: Bool,
                              didDismiss: (() -> Void)? = nil) -> some View {
        DiscardChangesWrapper(view: self, presentActionSheet: presentActionSheet, canDismiss: canDismiss, didDismiss: didDismiss)
    }
}
