import UIKit
import protocol WooFoundation.Analytics
import protocol Yosemite.StoresManager

/// Coordinates navigation for closing a WPCOM account from various entry points (settings and empty stores screens).
@MainActor final class CloseAccountCoordinator {
    private let sourceViewController: UIViewController
    private let removeAction: () async throws -> Void
    private let onRemoveSuccess: () -> Void
    private let stores: StoresManager
    private let analytics: Analytics

    /// - Parameters:
    ///   - sourceViewController: the view controller that presents the in-progress UI and alerts.
    ///   - removeAction: called when the remove action is confirmed.
    ///   - onRemoveSuccess: called when the removal is successful.
    init(sourceViewController: UIViewController,
         removeAction: @escaping () async throws -> Void,
         onRemoveSuccess: @escaping () -> Void,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.sourceViewController = sourceViewController
        self.removeAction = removeAction
        self.onRemoveSuccess = onRemoveSuccess
        self.stores = stores
        self.analytics = analytics
    }

    func start() {
        presentConfirmationAlert()
    }
}

private extension CloseAccountCoordinator {
    func presentConfirmationAlert() {
        // TODO: 7068 - analytics

        let username = stores.sessionManager.defaultAccount?.username ?? ""
        let message = String.localizedStringWithFormat(Localization.ConfirmationAlert.alertMessageFormat, username)
        let alertController = UIAlertController(title: Localization.ConfirmationAlert.alertTitle,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addActionWithTitle(Localization.ConfirmationAlert.cancelButtonTitle, style: .cancel) { _ in }
        let closeAccountAction = alertController.addActionWithTitle(Localization.ConfirmationAlert.removeButtonTitle,
                                                                    style: .destructive) { [weak self] _ in
            guard let self = self else { return }

            // TODO: 7068 - analytics

            self.presentInProgressUI()

            Task { @MainActor [weak self] in
                guard let self = self else { return }

                var dismissInProgressUICompletion: () -> Void

                do {
                    try await self.removeAction()
                    dismissInProgressUICompletion = { [weak self] in
                        self?.analytics.track(event: .closeAccountSuccess())
                        self?.onRemoveSuccess()
                    }
                } catch {
                    dismissInProgressUICompletion = { [weak self] in
                        self?.analytics.track(event: .closeAccountFailed(error: error))
                        DDLogError("⛔️ Cannot close account: \(error)")
                        self?.presentErrorAlert(error: error)
                    }
                }

                self.dismissInProgressUI(completion: dismissInProgressUICompletion)
            }
        }

        // Enables close account button based on whether the username matches the user input.
        closeAccountAction.isEnabled = false

        // Username text field.
        alertController.addTextField { textField in
            textField.clearButtonMode = .always
            textField.on(.editingChanged) { textField in
                closeAccountAction.isEnabled = textField.text == username
            }
        }

        sourceViewController.present(alertController, animated: true)
    }

    func presentInProgressUI() {
        let viewProperties = InProgressViewProperties(title: Localization.InProgressView.title, message: "")
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)
        inProgressViewController.modalPresentationStyle = .overFullScreen
        sourceViewController.present(inProgressViewController, animated: true)
    }

    func dismissInProgressUI(completion: @escaping () -> Void) {
        sourceViewController.dismiss(animated: true, completion: completion)
    }

    func presentErrorAlert(error: Error) {
        let alertController = UIAlertController(title: Localization.ErrorAlert.alertTitle,
                                                message: generateLocalizedMessage(error: error),
                                                preferredStyle: .alert)
        alertController.addActionWithTitle(Localization.ErrorAlert.contactSupportButtonTitle, style: .default) { [weak self] _ in
            guard let self = self else { return }
            let supportForm = SupportFormHostingController(viewModel: .init())
            supportForm.show(from: self.sourceViewController)
        }
        alertController.addActionWithTitle(Localization.ErrorAlert.dismissButtonTitle, style: .cancel) { _ in }
        sourceViewController.present(alertController, animated: true)
    }

    func generateLocalizedMessage(error: Error) -> String {
        let errorCode = errorCode(error: error)

        switch errorCode {
        case "unauthorized":
            return NSLocalizedString("You're not authorized to close the account.",
                                     comment: "Error message displayed when unable to close user account due to being unauthorized.")
        case "atomic-site":
            return NSLocalizedString("To close this account now, contact our support team.",
                                     comment: "Error message displayed when unable to close user account due to having active atomic site.")
        case "chargebacked-site":
            return NSLocalizedString("This user account cannot be closed if there are unresolved chargebacks.",
                                     comment: "Error message displayed when unable to close user account due to unresolved chargebacks.")
        case "active-subscriptions":
            return NSLocalizedString("This user account cannot be closed while it has active subscriptions.",
                                     comment: "Error message displayed when unable to close user account due to having active subscriptions.")
        case "active-memberships":
            return NSLocalizedString("This user account cannot be closed while it has active purchases.",
                                     comment: "Error message displayed when unable to close user account due to having active purchases.")
        default:
            return NSLocalizedString("An error occured while closing account.",
                                     comment: "Default error message displayed when unable to close user account.")
        }
    }

    func errorCode(error: Error) -> String? {
        let userInfo = (error as NSError).userInfo
        let errorCode = userInfo[Constants.dotcomAPIErrorCodeKey] as? String
        return errorCode
    }
}

private extension CloseAccountCoordinator {
    enum Localization {
        enum InProgressView {
            static let title = NSLocalizedString(
                "Closing account...",
                comment: "Title of the Close Account in-progress view."
            )
        }

        enum ConfirmationAlert {
            static let alertTitle = NSLocalizedString(
                "Confirm Close Account",
                comment: "Close Account confirmation alert title."
            )
            static let alertMessageFormat = NSLocalizedString(
                "To confirm, please re-enter your username before closing.\n\n%1$@",
                comment: "Close Account confirmation alert message. The %1$@ is the user's WordPress.com username."
            )
            static let cancelButtonTitle = NSLocalizedString(
                "Cancel",
                comment: "Close Account button title - dismisses alert, which cancels the Close Account attempt."
            )

            static let removeButtonTitle = NSLocalizedString(
                "Permanently Close Account",
                comment: "Close Account button title - confirms and closes user's WordPress.com account."
            )
        }

        enum ErrorAlert {
            static let alertTitle = NSLocalizedString(
                "Couldn’t close account automatically",
                comment: "Error title displayed when unable to close user account."
            )
            static let contactSupportButtonTitle = NSLocalizedString(
                "Contact Support",
                comment: "Close Account error alert button title - navigates the user to contact support."
            )
            static let dismissButtonTitle = NSLocalizedString(
                "Cancel",
                comment: "Close Account error alert button title - dismisses error alert."
            )
        }
    }
}

private extension CloseAccountCoordinator {
    enum Constants {
        static let dotcomAPIErrorCodeKey = "WordPressComRestApiErrorCodeKey"
    }
}

enum CloseAccountError: Error {
    case presenterDeallocated
}
