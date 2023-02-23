import UIKit
import Yosemite

/// Coordinates the Jetpack setup flow in the authenticated state.
///
final class JetpackSetupCoordinator {
    let navigationController: UINavigationController

    private let site: Site
    /// Whether Jetpack is installed and activated and only connection needs to be handled.
    private var connectionOnly: Bool
    private let stores: StoresManager
    private let analytics: Analytics

    init(site: Site,
         navigationController: UINavigationController,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.site = site
        self.connectionOnly = false // to be updated later after fetching Jetpack status
        self.navigationController = navigationController
        self.stores = stores
        self.analytics = analytics
    }

    func showBenefitModal() {
        let benefitsController = JetpackBenefitsHostingController()
        benefitsController.setActions { [weak self] in
            self?.navigationController.dismiss(animated: true, completion: { [weak self] in
                guard let self else { return }
                self.analytics.track(event: .jetpackInstallButtonTapped(source: .benefitsModal))

                guard !self.site.isJetpackCPConnected else {
                    let installController = JCPJetpackInstallHostingController(siteID: self.site.siteID,
                                                                               siteURL: self.site.url,
                                                                               siteAdminURL: self.site.adminURL)

                    installController.setDismissAction { [weak self] in
                        self?.navigationController.dismiss(animated: true, completion: nil)
                    }
                    self.navigationController.present(installController, animated: true, completion: nil)
                    return
                }

                #warning("show Jetpack setup flow for non-Jetpack sites")
            })
        } dismissAction: { [weak self] in
            self?.navigationController.dismiss(animated: true, completion: nil)
        }
        navigationController.present(benefitsController, animated: true, completion: nil)
    }
}
