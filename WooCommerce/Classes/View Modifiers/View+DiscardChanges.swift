import SwiftUI

/// `SwiftUI` wrapper adding a "discard changes" prompt on the dismiss drag gesture for the provided view.
///
struct DiscardChangesWrapper<Content: View>: UIViewControllerRepresentable {
    let view: Content

    /// Whether the view can be dismissed. When `false` the discard changes prompt is displayed.
    ///
    @Binding var canDismiss: Bool

    /// Optional method to be invoked when the view is dismissed.
    ///
    let didDismiss: (() -> Void)?

    typealias UIViewControllerType = UIHostingController<Content>

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let viewController = UIHostingController(rootView: view)

        // Sets the presentation controller delegate on the hosting controller
        context.coordinator.parentObserver = viewController.observe(\.parent, changeHandler: { vc, _ in
            vc.parent?.presentationController?.delegate = context.coordinator
        })

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // No-op
    }

    func makeCoordinator() -> Self.Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        let wrapper: DiscardChangesWrapper
        var parentObserver: NSKeyValueObservation?

        init(_ wrapper: DiscardChangesWrapper) {
            self.wrapper = wrapper
        }

        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            wrapper.canDismiss
        }

        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            UIAlertController.presentDiscardChangesActionSheet(viewController: presentationController.presentedViewController) { [weak self] in
                presentationController.presentedViewController.dismiss(animated: true)
                self?.wrapper.didDismiss?()
            }
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            wrapper.didDismiss?()
        }
    }
}

extension View {
    /// Adds a discard changes prompt on the dismiss drag gesture for the provided view.
    /// - Parameters:
    ///   - canDismiss: Whether the view can be dismissed. When `false` the discard changes prompt is displayed.
    ///   - didCancelFlow: Optional method to be invoked when the view is dismissed.
    func discardChangesPrompt(canDismiss: Binding<Bool>, didDismiss: (() -> Void)? = nil) -> some View {
        DiscardChangesWrapper(view: self, canDismiss: canDismiss, didDismiss: didDismiss)
    }
}
