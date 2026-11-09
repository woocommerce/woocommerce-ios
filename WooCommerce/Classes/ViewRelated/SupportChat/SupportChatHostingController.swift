import SwiftUI
import UIKit
import Yosemite

/// Hosting controller for the AI support chat view.
///
final class SupportChatHostingController: TabBarHidingHostingController<SupportChatView> {

    private let viewModel: SupportChatViewModel

    /// Retains the Jetpack setup coordinator while the flow is active.
    private var jetpackSetupCoordinator: JetpackSetupCoordinator?
    private var preferencesDismissHandler: PresentationDismissHandler?

    init(viewModel: SupportChatViewModel) {
        self.viewModel = viewModel
        let view = SupportChatView(viewModel: viewModel)
        super.init(rootView: view)

        viewModel.onStartJetpackSetup = { [weak self] in
            self?.startJetpackSetup()
        }
        viewModel.onUpdateWooCommercePlugin = { [weak self] onDismissed in
            self?.presentWooCommercePluginUpdate(onDismissed: onDismissed)
        }
        viewModel.onOpenPushNotificationPreferences = { [weak self] onDismissed in
            self?.presentPushNotificationPreferences(onDismissed: onDismissed)
        }
    }

    @available(*, unavailable)
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
    }

    private func startJetpackSetup() {
        guard let site = viewModel.site else { return }
        let coordinator = JetpackSetupCoordinator(site: site, rootViewController: self, onCompletion: { [weak self] in
            self?.viewModel.replaceActionWithRetry()
            self?.jetpackSetupCoordinator = nil
        })
        jetpackSetupCoordinator = coordinator
        coordinator.startSetup()
    }

    private func presentWooCommercePluginUpdate(onDismissed: @escaping () -> Void) {
        guard let site = viewModel.site,
              let url = URL(string: site.adminURL + WooConstants.wooCommercePluginUpdatePath) else {
            onDismissed()
            return
        }
        let webView = AuthenticatableWebView(url: url, title: Localization.updateWooCommerce, onDismiss: onDismissed)
        let viewController = UIHostingController(rootView: webView)
        viewController.modalPresentationStyle = .formSheet
        present(viewController, animated: true)
    }

    private func presentPushNotificationPreferences(onDismissed: @escaping () -> Void) {
        guard let siteID = viewModel.site?.siteID else {
            onDismissed()
            return
        }

        let navigationController = WooNavigationController()
        let viewController = PushNotificationPreferencesHostingController(siteID: siteID)
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak navigationController] _ in
                onDismissed()
                navigationController?.dismiss(animated: true)
            }
        )
        navigationController.viewControllers = [viewController]
        navigationController.modalPresentationStyle = .formSheet
        let dismissHandler = PresentationDismissHandler(onDismissed: onDismissed)
        preferencesDismissHandler = dismissHandler
        navigationController.presentationController?.delegate = dismissHandler
        present(navigationController, animated: true)
    }
}

private final class PresentationDismissHandler: NSObject, UIAdaptivePresentationControllerDelegate {
    private let onDismissed: () -> Void

    init(onDismissed: @escaping () -> Void) {
        self.onDismissed = onDismissed
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismissed()
    }
}

// MARK: - Presentation
//
extension SupportChatHostingController {

    /// Creates a support chat for login flows, including escalation to human support.
    static func makeForPreLogin(siteAddress: String? = nil,
                                initialMessage: String? = nil,
                                excludeStoreResponseExcerptsFromLogs: Bool = false) -> SupportChatHostingController {
        weak var viewModel: SupportChatViewModel?
        var escalationCoordinator: SupportEscalationCoordinator?
        weak var hostingController: SupportChatHostingController?
        let chatViewModel = SupportChatViewModel(
            entryPoint: .preLogin,
            initialContext: siteAddress.map { ["site_url": .string($0)] },
            initialMessage: initialMessage,
            supportSiteAddress: siteAddress,
            excludeStoreResponseExcerptsFromLogs: excludeStoreResponseExcerptsFromLogs,
            onContactHumanSupport: { chatID, transcript, supportAreaInfo, entryPoint, hasReceivedBotResponse in
                escalationCoordinator = SupportEscalationCoordinator(
                    navigationController: hostingController?.navigationController,
                    mobileStatusReportProvider: MobileStatusReportProvider(),
                    onTicketCreated: { [weak viewModel] in viewModel?.markChatTicketCreated() }
                )
                escalationCoordinator?.handleEscalation(
                    chatID: chatID,
                    transcript: transcript,
                    supportAreaInfo: supportAreaInfo,
                    entryPoint: entryPoint,
                    siteAddress: siteAddress,
                    hasReceivedBotResponse: hasReceivedBotResponse
                )
            }
        )
        viewModel = chatViewModel
        let controller = SupportChatHostingController(viewModel: chatViewModel)
        hostingController = controller
        return controller
    }

    /// Shows the support chat from the given view controller.
    ///
    /// - Parameter presenter: The view controller to present from.
    func show(from presenter: UIViewController) {
        if let navigationController = presenter.navigationController {
            navigationController.pushViewController(self, animated: true)
        } else {
            let navigationController = UINavigationController(rootViewController: self)
            navigationController.modalPresentationStyle = .formSheet
            presenter.present(navigationController, animated: true)
        }
    }
}

// MARK: - Localization
//
private extension SupportChatHostingController {
    enum Localization {
        static let updateWooCommerce = NSLocalizedString(
            "supportChatHostingController.updateWooCommerce",
            value: "Update WooCommerce",
            comment: "Title of the web view to update WooCommerce plugin from support chat"
        )
    }
}
