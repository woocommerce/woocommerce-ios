import Combine
import Foundation
import Yosemite

/// View model for `JetpackInstallStepsView`
///
final class JetpackInstallStepsViewModel: ObservableObject {
    /// ID of the site to install Jetpack-the-plugin to.
    ///
    private let siteID: Int64

    /// Stores manager to handle install steps.
    ///
    private let stores: StoresManager

    /// Current step of the installation
    ///
    @Published private(set) var currentStep: JetpackInstallStep?

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    /// Starts the steps by installing the Jetpack plugin.
    ///
    func startInstallation() {
        currentStep = .installation
        let installationAction = SitePluginAction.installSitePlugin(siteID: siteID, slug: Constants.jetpackSlug) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.activateJetpack()
            case .failure:
                // TODO-5365: handle failure with an error message
                break
            }
        }
        stores.dispatch(installationAction)
    }

    /// Activates the installed Jetpack plugin.
    ///
    private func activateJetpack() {
        currentStep = .activation
        let activationAction = SitePluginAction.activateSitePlugin(siteID: siteID, pluginName: Constants.jetpackPluginName) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.checkSiteConnection()
            case .failure:
                // TODO-5365: handle failure with an error message
                break
            }
        }
        stores.dispatch(activationAction)
    }

    /// Check site to make sure connection succeeds.
    ///
    private func checkSiteConnection() {
        currentStep = .connection
        let siteFetch = AccountAction.loadAndSynchronizeSite(siteID: siteID,
                                                             forcedUpdate: true,
                                                             isJetpackConnectionPackageSupported: true) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let site):
                print("😛 \(site.isWooCommerceActive)")
                guard site.isWooCommerceActive, !site.isJetpackCPConnected else {
                    // TODO-5365: handle failure with an error message
                    return
                }
                self.currentStep = .done
            case .failure(let error):
                // TODO-5365: handle failure with an error message
                print(error)
            }
        }
        stores.dispatch(siteFetch)
    }
}

private extension JetpackInstallStepsViewModel {
    enum Constants {
        static let jetpackSlug: String = "jetpack"
        static let jetpackPluginName: String = "jetpack/jetpack"
    }
}
