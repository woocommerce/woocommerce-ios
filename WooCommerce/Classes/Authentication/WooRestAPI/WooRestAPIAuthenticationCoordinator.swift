import UIKit
import struct WordPressAuthenticator.WordPressOrgCredentials
import Yosemite

final class WooRestAPIAuthenticationCoordinator: Coordinator {
    let navigationController: UINavigationController

    private var storePickerCoordinator: StorePickerCoordinator?

    private let analytics: Analytics

    init(navigationController: UINavigationController,
         analytics: Analytics = ServiceLocator.analytics) {
        self.navigationController = navigationController
        self.analytics = analytics
    }

    func start() {
        let accountCreationController = WooRestAPIAuthenticationFormHostingController(
            viewModel: .init(),
            analytics: analytics
        ) { [weak self] credentials in
            guard let self else { return }
            self.handleCredentials(credentials)

            // Generating site credentials isn't working at the moment
            // The callback URL with the credentials isn't being fired.
            // Need to debug this.
            //
            //self.generateCredentials(siteURL: "https://horrible-raven.jurassic.ninja/")
        }
        navigationController.show(accountCreationController, sender: self)
    }
}

private extension WooRestAPIAuthenticationCoordinator {

    func handleCredentials(_ credentials: WooRestAPICredentials) {
        ServiceLocator.stores.authenticate(wooRestAPICredentials: credentials)

        let onDismiss = {}
        storePickerCoordinator = StorePickerCoordinator(navigationController, config: .login)
        storePickerCoordinator?.onDismiss = onDismiss
        storePickerCoordinator?.didSelectStore(with: 0, onCompletion: onDismiss)
    }
}

// MARK: - Webview based authentication

private extension WooRestAPIAuthenticationCoordinator {
    func generateCredentials(siteURL: String) {
        guard let viewModel = try? WooRestAPIAuthenticationWebViewModel(siteURL: siteURL, completion: { [weak self] in
            //self?.fetchJetpackUser(in: viewController)
        }) else {
            return
        }

        let webViewController = AuthenticatedWebViewController(viewModel: viewModel)
        webViewController.addCloseNavigationBarButton(target: self, action: #selector(handleCloseAction))
        let webNavigationController = WooNavigationController(rootViewController: webViewController)
        // Disables interactive dismissal of the store creation modal.
        webNavigationController.isModalInPresentation = true

        presentAuthenticationFlow(viewController: webNavigationController)
    }

    @objc func handleCloseAction() {
        navigationController.dismiss(animated: true)    }

    func presentAuthenticationFlow(viewController: UIViewController) {
        // If the navigation controller is already presenting another view, the view needs to be dismissed before store
        // creation view can be presented.
        if navigationController.presentedViewController != nil {
            navigationController.dismiss(animated: true) { [weak self] in
                self?.navigationController.present(viewController, animated: true)
            }
        } else {
            navigationController.present(viewController, animated: true)
        }
    }
}
