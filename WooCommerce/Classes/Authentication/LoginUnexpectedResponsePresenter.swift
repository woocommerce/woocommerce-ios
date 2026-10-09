import UIKit
import protocol WooFoundation.Analytics

/// Owns one alert or explicit retry at a time. Owners invalidate it when their login screen is abandoned.
@MainActor
final class LoginUnexpectedResponsePresenter {
    typealias Retry = (@escaping (Bool) -> Void) -> Void
    typealias Presentation = @MainActor (UIViewController, UIAlertController, @escaping () -> Void) -> Void
    private let analytics: Analytics
    private let presentation: Presentation
    private let support: ((UIViewController, LoginSupportContext) -> Void)?
    private var attemptID: UUID?
    private weak var alert: UIAlertController?
    private var actionHandler: ((LoginUnexpectedResponseFailure.Action) -> Void)?

    init(analytics: Analytics = ServiceLocator.analytics,
         presentation: @escaping Presentation = { $0.present($1, animated: true, completion: $2) },
         support: ((UIViewController, LoginSupportContext) -> Void)? = nil) {
        self.analytics = analytics
        self.presentation = presentation
        self.support = support
    }

    func present(failure: LoginUnexpectedResponseFailure, flow: LoginUnexpectedResponseFailure.LoginFlow,
                 from controller: UIViewController, siteURL: String? = nil, onRetry: @escaping Retry, onDismiss: @escaping () -> Void = {},
                 onContactSupport: @escaping () -> Void = {}) {
        guard attemptID == nil, controller.presentedViewController == nil else {
            return
        }
        let context = LoginSupportContext(failure: failure, flow: flow, siteURL: siteURL)
        let id = UUID()
        attemptID = id
        let alert = UIAlertController(title: Localization.title, message: Localization.message, preferredStyle: .alert)
        self.alert = alert
        actionHandler = { [weak self, weak controller, weak alert] action in
            guard let self, let controller, attemptID == id else {
                return
            }
            actionHandler = nil
            analytics.track(event: .Login.unexpectedResponseActionTapped(failure: failure, loginFlow: flow, action: action))
            let continuation = { [weak self, weak controller] in
                guard let self, let controller, attemptID == id else {
                    return
                }
                self.alert = nil
                if action == .retry {
                    onRetry { [weak self] success in
                        guard let self, attemptID == id else {
                            return
                        }
                        attemptID = nil
                        analytics.track(event: .Login.unexpectedResponseRetryResult(failure: failure, loginFlow: flow, success: success))
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
            if alert?.presentingViewController != nil {
                alert?.dismiss(animated: true, completion: continuation)
            } else {
                continuation()
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
        presentation(controller, alert) { [weak self] in
            guard let self, attemptID == id, !shown else {
                return
            }
            shown = true
            analytics.track(event: .Login.unexpectedResponseShown(failure: failure, loginFlow: flow))
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
        weak var model: SupportChatViewModel?
        var escalation: SupportEscalationCoordinator?
        weak var host: SupportChatHostingController?
        let chat = SupportChatViewModel(entryPoint: .preLogin,
                                        initialContext: context.siteURL.map { ["site_url": .string($0)] },
                                        initialMessage: context.initialMessage,
                                        supportSiteAddress: context.siteURL,
                                        onContactHumanSupport: { chatID, transcript, area, entryPoint, receivedResponse in
            escalation = SupportEscalationCoordinator(navigationController: host?.navigationController,
                                                      mobileStatusReportProvider: MobileStatusReportProvider(),
                                                      onTicketCreated: { [weak model] in model?.markChatTicketCreated() })
            escalation?.handleEscalation(chatID: chatID, transcript: transcript, supportAreaInfo: area,
                                        entryPoint: entryPoint, siteAddress: context.siteURL, hasReceivedBotResponse: receivedResponse)
        })
        model = chat
        let chatController = SupportChatHostingController(viewModel: chat)
        host = chatController
        chatController.show(from: (controller as? UINavigationController)?.topViewController ?? controller)
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
