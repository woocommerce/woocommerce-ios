import UIKit

/// Coordinates navigation for removing Apple ID access from various entry points (settings and empty stores screens).
final class RemoveAppleIDAccessCoordinator {
    private let sourceViewController: UIViewController
    private let removeAction: () async -> Result<Void, Error>
    private let onRemoveSuccess: () -> Void

    /// - Parameters:
    ///   - sourceViewController: the view controller that presents the in-progress UI and alerts.
    ///   - removeAction: called when the remove action is confirmed.
    ///   - onRemoveSuccess: called when the removal is successful.
    init(sourceViewController: UIViewController,
         removeAction: @escaping () async -> Result<Void, Error>,
         onRemoveSuccess: @escaping () -> Void) {
        self.sourceViewController = sourceViewController
        self.removeAction = removeAction
        self.onRemoveSuccess = onRemoveSuccess
    }

    func start() {
        presentConfirmationAlert()
    }
}

private extension RemoveAppleIDAccessCoordinator {
    func presentConfirmationAlert() {
        // TODO: 7068 - analytics
        let alertController = UIAlertController(title: Localization.ConfirmationAlert.alertTitle,
                                                message: Localization.ConfirmationAlert.alertMessage,
                                                preferredStyle: .alert)
        alertController.addActionWithTitle(Localization.ConfirmationAlert.cancelButtonTitle, style: .cancel) { _ in }
        alertController.addActionWithTitle(Localization.ConfirmationAlert.removeButtonTitle, style: .destructive) { [weak self] _ in
            guard let self = self else { return }

            // TODO: 7068 - analytics

            self.presentInProgressUI()

            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let result = await self.removeAction()
                self.dismissInProgressUI { [weak self] in
                    guard let self = self else { return }
                    switch result {
                    case .success:
                        self.onRemoveSuccess()
                    case .failure(let error):
                        DDLogError("⛔️ Cannot remove Apple ID access: \(error)")
                        self.presentErrorAlert()
                    }
                }
            }
        }
        sourceViewController.present(alertController, animated: true)
    }

    func presentInProgressUI() {
        let viewProperties = InProgressViewProperties(title: Localization.RemoveAppleIDAccessInProgressView.title, message: "")
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)
        inProgressViewController.modalPresentationStyle = .overFullScreen
        sourceViewController.present(inProgressViewController, animated: true)
    }

    func dismissInProgressUI(completion: @escaping () -> Void) {
        sourceViewController.dismiss(animated: true, completion: completion)
    }

    func presentErrorAlert() {
        let alertController = UIAlertController(title: Localization.ErrorAlert.alertTitle,
                                                message: Localization.ErrorAlert.alertMessage,
                                                preferredStyle: .alert)
        alertController.addActionWithTitle(Localization.ErrorAlert.dismissButtonTitle, style: .cancel) { _ in }
        sourceViewController.present(alertController, animated: true)
    }
}

private extension RemoveAppleIDAccessCoordinator {
    enum Localization {
        enum RemoveAppleIDAccessInProgressView {
            static let title = NSLocalizedString(
                "Removing Apple ID Access...",
                comment: "Title of the Remove Apple ID Access in-progress view."
            )
        }

        enum ConfirmationAlert {
            static let alertTitle = NSLocalizedString(
                "Remove Apple ID Access",
                comment: "Remove Apple ID Access confirmation alert title - confirms and revokes Apple ID token."
            )
            static let alertMessage = NSLocalizedString(
                "This will log you out and reset your Sign In With Apple access token. " +
                "You will be asked to re-enter your WordPress.com password if you Sign In With Apple again.",
                comment: "Alert message to confirm a user meant to remove Apple ID access."
            )
            static let cancelButtonTitle = NSLocalizedString(
                "Cancel",
                comment: "Alert button title - dismisses alert, which cancels the Remove Apple ID Access attempt."
            )

            static let removeButtonTitle = NSLocalizedString(
                "Remove",
                comment: "Remove Apple ID Access button title - confirms and revokes Apple ID token."
            )
        }

        enum ErrorAlert {
            static let alertTitle = NSLocalizedString(
                "Error Removing Apple ID Access",
                comment: "Remove Apple ID Access error alert title."
            )
            static let alertMessage = NSLocalizedString(
                "Please try again or contact us for support.",
                comment: "Remove Apple ID Access error alert message."
            )
            static let dismissButtonTitle = NSLocalizedString(
                "OK",
                comment: "Alert button title - dismisses Remove Apple ID Access error alert."
            )
        }
    }
}

enum RemoveAppleIDAccessError: Error {
    case noCredentials
    case presenterDeallocated
}
