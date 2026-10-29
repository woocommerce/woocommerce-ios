import UIKit
import protocol WooFoundation.Analytics

/// Owns one alert or explicit retry at a time. Owners invalidate it when their login screen is abandoned.
@MainActor
final class LoginUnexpectedResponsePresenter {
    /// Retry callers deliver results on the main actor, including through Sendable action completions.
    typealias RetryResult = @Sendable (Bool) -> Void
    typealias Retry = (@escaping RetryResult) -> Void
    typealias Presentation = @MainActor (UIViewController, UIAlertController, @escaping () -> Void) -> Void
    typealias AlertDismissal = @MainActor (UIAlertController, @escaping () -> Void) -> Void
    private let analytics: Analytics
    private let presentation: Presentation
    private let support: ((UIViewController, LoginSupportContext) -> Void)?
    private let alertDismissal: AlertDismissal
    private var attemptID: UUID?
    private weak var alert: UIAlertController?
    private var actionHandler: ((LoginUnexpectedResponseFailure.Action) -> Void)?

    init(analytics: Analytics = ServiceLocator.analytics,
         presentation: @escaping Presentation = { $0.present($1, animated: true, completion: $2) },
         alertDismissal: @escaping AlertDismissal = { $0.dismiss(animated: false, completion: $1) },
         support: ((UIViewController, LoginSupportContext) -> Void)? = nil) {
        self.analytics = analytics
        self.presentation = presentation
        self.alertDismissal = alertDismissal
        self.support = support
    }

    func present(failure: LoginUnexpectedResponseFailure, flow: LoginUnexpectedResponseFailure.LoginFlow,
                 from controller: UIViewController, siteURL: String? = nil, onRetry: @escaping Retry, onDismiss: @escaping () -> Void = {},
                 onContactSupport: @escaping () -> Void = {}) {
        guard attemptID == nil else {
            return
        }
        let context = LoginSupportContext(failure: failure, flow: flow, siteURL: siteURL)
        let presentationController = topmostPresentedController(from: controller)
        let id = UUID()
        attemptID = id
        let alert = UIAlertController(title: Localization.title, message: Localization.message, preferredStyle: .alert)
        self.alert = alert
        actionHandler = { [weak self, weak controller] action in
            guard let self, let controller, attemptID == id else {
                return
            }
            actionHandler = nil
            analytics.track(event: .Login.unexpectedResponseActionTapped(failure: failure, loginFlow: flow, action: action))
            self.alert = nil
            if action == .retry {
                onRetry { [weak self] success in
                    // Login tasks run on the main actor; role and site remotes deliver completions on the main queue.
                    MainActor.assumeIsolated {
                        guard let self, self.attemptID == id else {
                            return
                        }
                        self.attemptID = nil
                        self.analytics.track(event: .Login.unexpectedResponseRetryResult(failure: failure, loginFlow: flow, success: success))
                    }
                }
            } else {
                attemptID = nil
                if action == .contactSupport {
                    onContactSupport()
                    showSupport(from: controller, context: context)
                } else {
                    onDismiss()
                }
            }
        }
        for (action, title) in [(LoginUnexpectedResponseFailure.Action.retry, Localization.retry),
                                (.contactSupport, Localization.support), (.dismiss, Localization.dismiss)] {
            alert.addAction(UIAlertAction(title: title, style: action == .dismiss ? .cancel : .default) { [weak self] _ in
                guard self?.attemptID == id else { return }
                self?.select(action)
            })
        }
        var shown = false
        let presentAlert = { [weak self] (controller: UIViewController) in
            guard let self, attemptID == id else {
                return
            }
            presentation(controller, alert) { [weak self] in
                guard let self, attemptID == id, !shown else {
                    return
                }
                shown = true
                analytics.track(event: .Login.unexpectedResponseShown(failure: failure, loginFlow: flow))
            }
        }
        if let existingAlert = presentationController as? UIAlertController {
            let replacementController = existingAlert.presentingViewController ?? controller
            alertDismissal(existingAlert) {
                presentAlert(replacementController)
            }
        } else {
            presentAlert(presentationController)
        }
    }

    func select(_ action: LoginUnexpectedResponseFailure.Action) {
        actionHandler?(action)
    }

    func invalidate() {
        attemptID = nil
        actionHandler = nil
        alert?.dismiss(animated: false)
        alert = nil
    }

    private func showSupport(from controller: UIViewController, context: LoginSupportContext) {
        if let support {
            return support(controller, context)
        }
        let chatController = SupportChatHostingController.makeForPreLogin(
            siteAddress: context.siteURL,
            initialMessage: context.initialMessage,
            excludeStoreResponseExcerptsFromLogs: true
        )
        chatController.show(from: (controller as? UINavigationController)?.topViewController ?? controller)
    }

    private func topmostPresentedController(from controller: UIViewController) -> UIViewController {
        var controller = controller
        while let presentedController = controller.presentedViewController {
            controller = presentedController
        }
        return controller
    }

    private enum Localization {
        static let title = NSLocalizedString("com.woocommerce.login.unexpectedResponse.title", value: "Unable to log in",
                                             comment: "Unexpected login response alert title")
        static let message = NSLocalizedString(
            "com.woocommerce.login.unexpectedResponse.message",
            value: "Your store returned an unexpected response, so we couldn’t finish logging you in. Try again or contact support for help.",
            comment: "Unexpected login response alert message")
        static let retry = NSLocalizedString("com.woocommerce.login.unexpectedResponse.retry", value: "Try Again", comment: "Retry the failed login step")
        static let support = NSLocalizedString("com.woocommerce.login.unexpectedResponse.support", value: "Contact Support", comment: "Open AI support for login")
        static let dismiss = NSLocalizedString("com.woocommerce.login.unexpectedResponse.dismiss", value: "Dismiss", comment: "Dismiss the login failure alert")
    }
}
