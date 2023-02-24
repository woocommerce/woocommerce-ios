import UIKit
import Yosemite
import enum Alamofire.AFError

/// Coordinates the Jetpack setup flow in the authenticated state.
///
final class JetpackSetupCoordinator {
    let navigationController: UINavigationController

    private let site: Site
    /// Whether Jetpack is installed and activated and only connection needs to be handled.
    private var requiresConnectionOnly: Bool
    private let stores: StoresManager
    private let analytics: Analytics

    init(site: Site,
         navigationController: UINavigationController,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.site = site
        self.requiresConnectionOnly = false // to be updated later after fetching Jetpack status
        self.navigationController = navigationController
        self.stores = stores
        self.analytics = analytics
    }

    func showBenefitModal() {
        let benefitsController = JetpackBenefitsHostingController(isJetpackCPSite: site.isJetpackCPConnected)
        benefitsController.setActions (installAction: { [weak self] result in
            guard let self else { return }
            self.analytics.track(event: .jetpackInstallButtonTapped(source: .benefitsModal))
            if self.site.isNonJetpackSite {
                self.checkJetpackStatus(result)
            } else {
                self.presentJCPJetpackInstallFlow()
            }
        }, dismissAction: { [weak self] in
            self?.navigationController.dismiss(animated: true, completion: nil)
        })
        navigationController.present(benefitsController, animated: true, completion: nil)
    }
}

// MARK: - Private helpers
//
private extension JetpackSetupCoordinator {
    /// Navigates to the Jetpack installation flow for JCP sites.
    func presentJCPJetpackInstallFlow() {
        navigationController.dismiss(animated: true, completion: { [weak self] in
            guard let self else { return }
            let installController = JCPJetpackInstallHostingController(siteID: self.site.siteID,
                                                                       siteURL: self.site.url,
                                                                       siteAdminURL: self.site.adminURL)

            installController.setDismissAction { [weak self] in
                self?.navigationController.dismiss(animated: true, completion: nil)
            }
            self.navigationController.present(installController, animated: true, completion: nil)
        })
    }

    /// Checks the Jetpack connection status for non-Jetpack sites to infer the setup steps to be handled.
    func checkJetpackStatus(_ result: Result<JetpackUser, Error>) {
        switch result {
        case .success(let user):
            let connectedEmail = user.wpcomUser?.email
            requiresConnectionOnly = !user.isConnected
            #warning("TODO: start WPCom auth with connectedEmail")
            DDLogInfo("✅ connected email: \(connectedEmail), isConnected: \(user.isConnected)")
        case .failure(let error):
            DDLogError("⛔️ Jetpack status fetched error: \(error)")
            switch error {
            case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404)):
                /// 404 error means Jetpack is not installed or activated yet.
                requiresConnectionOnly = false
                let roles = stores.sessionManager.defaultRoles
                if roles.contains(.administrator) {
                    #warning("TODO: start WPCom auth")
                } else {
                    displayAdminRoleRequiredError()
                }
            case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 403)):
                /// 403 means the site Jetpack connection is not established yet
                /// and the user has no permission to handle this.
                displayAdminRoleRequiredError()
            default:
                #warning("TODO: show generic error alert")
                break
            }
        }
    }

    func displayAdminRoleRequiredError() {
        let viewController = AdminRoleRequiredHostingController { [weak self] in
            self?.navigationController.dismiss(animated: true)
        }
        navigationController.presentedViewController?.present(UINavigationController(rootViewController: viewController), animated: true)
    }
}
