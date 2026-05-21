import SwiftUI
import UIKit

/// Hosting controller for the AI support chat view.
///
final class SupportChatHostingController: UIHostingController<SupportChatView> {

    private let viewModel: SupportChatViewModel

    /// Retains the Jetpack setup coordinator while the flow is active.
    private var jetpackSetupCoordinator: JetpackSetupCoordinator?
    private var preferencesDismissHandler: PresentationDismissHandler?

    init(viewModel: SupportChatViewModel) {
        self.viewModel = viewModel
        let view = SupportChatView(viewModel: viewModel)
        super.init(rootView: view)

        self.hidesBottomBarWhenPushed = true
        self.title = Localization.title

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
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
    }

    private func startJetpackSetup() {
        guard let site = ServiceLocator.stores.sessionManager.defaultSite else { return }
        let coordinator = JetpackSetupCoordinator(site: site, rootViewController: self, onCompletion: { [weak self] in
            self?.viewModel.replaceActionWithRetry()
            self?.jetpackSetupCoordinator = nil
        })
        jetpackSetupCoordinator = coordinator
        coordinator.startSetup()
    }

    private func presentWooCommercePluginUpdate(onDismissed: @escaping () -> Void) {
        guard let site = ServiceLocator.stores.sessionManager.defaultSite,
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
        guard let siteID = ServiceLocator.stores.sessionManager.defaultSite?.siteID else {
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
        static let title = NSLocalizedString(
            "supportChatHostingController.title",
            value: "Chat with Support",
            comment: "Navigation title for the AI support chat screen"
        )
        static let updateWooCommerce = NSLocalizedString(
            "supportChatHostingController.updateWooCommerce",
            value: "Update WooCommerce",
            comment: "Title of the web view to update WooCommerce plugin from support chat"
        )
    }
}
