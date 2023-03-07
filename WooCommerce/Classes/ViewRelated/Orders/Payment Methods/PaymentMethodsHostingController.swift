import SwiftUI

final class PaymentMethodsHostingController: UIHostingController<HostedPaymentMethodsView> {
    init(viewModel: PaymentMethodsViewModel) {
        super.init(rootView: HostedPaymentMethodsView(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController
        rootView.dismiss = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Needed to present IPP collect amount alerts, which are displayed in UIKit view controllers.
        rootView.rootViewController = navigationController

        // Set presentation delegate to track the user dismiss flow event
        if let navigationController = navigationController {
            navigationController.presentationController?.delegate = self
        } else {
            presentationController?.delegate = self
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct HostedPaymentMethodsView: View {
    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismiss: (() -> Void) = {}

    /// Needed because IPP capture payments using a UIViewController for providing user feedback.
    ///
    weak var rootViewController: UIViewController?

    /// ViewModel to render the view content.
    ///
    var viewModel: PaymentMethodsViewModel

    var body: some View {
        PaymentMethodsView(dismiss: dismiss, rootViewController: rootViewController, viewModel: viewModel)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(PaymentMethodsHostingController.Localization.cancelTitle, action: {
                        dismiss()
                        viewModel.userDidCancelFlow()
                    })
                    .accessibilityIdentifier(Accessibility.cancelButton)
                }
            }
            .wooNavigationBarStyle()
    }

}

private extension HostedPaymentMethodsView {
    enum Accessibility {
        static let cancelButton = "payment-methods-view-cancel-button"
    }
}

/// Intercepts to the dismiss drag gesture.
///
extension PaymentMethodsHostingController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        rootView.viewModel.userDidCancelFlow()
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.splitViewInOrdersTab) else {
            return !rootView.viewModel.disableViewActions
        }

        return rootView.viewModel.shouldEnableSwipeToDismiss
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.splitViewInOrdersTab) else {
            return
        }

        presentCancelOrderActionSheet(viewController: self) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
            self?.rootView.viewModel.userDidCancelFlow()
        }
    }

    private func presentCancelOrderActionSheet(viewController: UIViewController, onDismiss: ((UIAlertAction) -> Void)? = nil) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text
        actionSheet.addDestructiveActionWithTitle(Localization.dismissOrder, handler: onDismiss)
        actionSheet.addCancelActionWithTitle(Localization.cancelTitle)

        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = viewController.view.bounds
            popoverController.permittedArrowDirections = []
        }

        viewController.present(actionSheet, animated: true)
    }
}

private extension PaymentMethodsHostingController {
    enum Localization {
        static let cancelTitle = NSLocalizedString("Cancel", comment: "Title for the button to cancel the payment methods screen")

        static let dismissOrder = NSLocalizedString("Dismiss Order", comment: "Title for dismiss the action when dragging the screen down.")
    }
}
