import UIKit

final class WooRestAPIAuthenticationCoordinator: Coordinator {
    let navigationController: UINavigationController

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
        ) { [weak self] siteURL in
            guard let self else { return }
            self.generateCredentials(siteURL: siteURL)
        }
        navigationController.show(accountCreationController, sender: self)
    }
}

private extension WooRestAPIAuthenticationCoordinator {
    func generateCredentials(siteURL: String) {
        guard let viewModel = try? WooRestAPIAuthenticationWebViewModel(siteURL: siteURL, completion: { [weak self] in
            //self?.fetchJetpackUser(in: viewController)
        }) else {
            return
        }

        let webViewController = AuthenticatedWebViewController(viewModel: viewModel)
        webViewController.addCloseNavigationBarButton(target: self, action: #selector(handleStoreCreationCloseAction))
        let webNavigationController = WooNavigationController(rootViewController: webViewController)
        // Disables interactive dismissal of the store creation modal.
        webNavigationController.isModalInPresentation = true

        presentAuthenticationFlow(viewController: webNavigationController)
    }

    @objc func handleStoreCreationCloseAction() {
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
