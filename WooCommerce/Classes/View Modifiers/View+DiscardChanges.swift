import SwiftUI

/// `SwiftUI` wrapper adding a "discard changes" prompt on the dismiss drag gesture for the provided view.
///
struct DiscardChangesWrapper<Content: View>: UIViewControllerRepresentable {
    let view: Content

    /// Title for the discard changes action sheet.
    ///
    let actionSheetTitle: String?

    /// Message for the discard changes action sheet.
    ///
    let actionSheetMessage: String?

    /// Title for the discard changes button on the action sheet.
    ///
    let discardButtonTitle: String

    /// Title for the cancel button on the action sheet.
    ///
    let cancelButtonTitle: String

    /// Whether the view can be dismissed. When `false` the discard changes prompt is displayed.
    ///
    let canDismiss: Bool

    /// Optional method to be invoked when the view is dismissed.
    ///
    let didDismiss: (() -> Void)?

    typealias UIViewControllerType = UIHostingController<Content>

    func makeUIViewController(context: Context) -> UIViewControllerType {
        UIHostingController(rootView: view)
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
            let viewController = presentationController.presentedViewController

            let actionSheet = UIAlertController(title: wrapper.actionSheetTitle, message: wrapper.actionSheetMessage, preferredStyle: .actionSheet)
            actionSheet.view.tintColor = .text
            actionSheet.addDestructiveActionWithTitle(wrapper.discardButtonTitle) { [weak self] _ in
                viewController.dismiss(animated: true, completion: nil)
                self?.wrapper.didDismiss?()
            }
            actionSheet.addCancelActionWithTitle(wrapper.cancelButtonTitle)

            if let popoverController = actionSheet.popoverPresentationController {
                popoverController.sourceView = viewController.view
                popoverController.sourceRect = viewController.view.bounds
                popoverController.permittedArrowDirections = []
            }

            viewController.present(actionSheet, animated: true)
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            wrapper.didDismiss?()
        }
    }
}

struct CloseButtonWithDiscardPrompt: ViewModifier {
    let title: String
    let message: String
    let discardButtonTitle: String
    let cancelButtonTitle: String

    let showPrompt: Bool
    let didDismiss: (() -> Void)?

    @State private var isShowingPrompt: Bool = false
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        if showPrompt {
                            isShowingPrompt.toggle()
                        } else {
                            didDismiss?()
                            dismiss()
                        }
                    }, label: {
                        Image(uiImage: .closeButton)
                            .secondaryBodyStyle()
                    })
                }
            })
            .interactiveDismissDisabled()
            .confirmationDialog(title, isPresented: $isShowingPrompt) {
                Button(discardButtonTitle, role: .destructive, action: {
                    didDismiss?()
                    dismiss()
                })
                Button(cancelButtonTitle, role: .cancel, action: {})
            } message: {
                Text(message)
            }
    }
}

extension View {
    /// Adds a discard changes prompt on the dismiss drag gesture for the provided view.
    /// - Parameters:
    ///   - title: Optional title for the discard changes action sheet.
    ///   - message: Optional message for the discard changes action sheet. Defaults to "Are you sure you want to discard these changes?"
    ///   - discardButtonTitle: Title for the discard changes button on the action sheet. Defaults to "Discard changes".
    ///   - cancelButtonTitle: Title for the cancel button on the action sheet. Defaults to "Cancel".
    ///   - canDismiss: Whether the view can be dismissed. When `false` the discard changes prompt is displayed.
    ///   - didDismiss: Optional method to be invoked when the view is dismissed.
    func discardChangesPrompt(title: String? = nil,
                              message: String? = Localization.message,
                              discardButtonTitle: String = Localization.discard,
                              cancelButtonTitle: String = Localization.cancel,
                              canDismiss: Bool,
                              didDismiss: (() -> Void)? = nil) -> some View {
        DiscardChangesWrapper(view: self,
                              actionSheetTitle: title,
                              actionSheetMessage: message,
                              discardButtonTitle: discardButtonTitle,
                              cancelButtonTitle: cancelButtonTitle,
                              canDismiss: canDismiss,
                              didDismiss: didDismiss)
            .ignoresSafeArea() // Removes extra safe area insets added by the wrapper
    }

    /// Adds a close button with a discard changes prompt, and disables the dismiss drag gesture.
    /// - Parameters:
    ///   - title: Title for the discard changes action sheet. Defaults to empty string.
    ///   - message: Message for the discard changes action sheet. Defaults to "Are you sure you want to discard these changes?"
    ///   - discardButtonTitle: Title for the discard changes button on the action sheet. Defaults to "Discard changes".
    ///   - cancelButtonTitle: Title for the cancel button on the action sheet. Defaults to "Cancel".
    ///   - hasChanges: Whether there are changes to be discarded.
    ///   - didDismiss: Optional method to be invoked when the view is dismissed.
    func closeButtonWithDiscardChangesPrompt(title: String = "",
                                             message: String = Localization.message,
                                             discardButtonTitle: String = Localization.discard,
                                             cancelButtonTitle: String = Localization.cancel,
                                             hasChanges: Bool,
                                             didDismiss: (() -> Void)? = nil) -> some View {
        ModifiedContent(content: self, modifier: CloseButtonWithDiscardPrompt(title: title,
                                                                              message: message,
                                                                              discardButtonTitle: discardButtonTitle,
                                                                              cancelButtonTitle: cancelButtonTitle,
                                                                              showPrompt: hasChanges,
                                                                              didDismiss: didDismiss))
    }
}

// MARK: Constants
private enum Localization {
    static let message = NSLocalizedString("Are you sure you want to discard these changes?",
                                           comment: "Message title for Discard Changes Action Sheet")
    static let discard = NSLocalizedString("Discard changes",
                                          comment: "Button title Discard Changes in Discard Changes Action Sheet")
    static let cancel = NSLocalizedString("Cancel",
                                          comment: "Button title Cancel in Discard Changes Action Sheet")
}
