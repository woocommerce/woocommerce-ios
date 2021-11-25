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
    @Published private(set) var currentStep: JetpackInstallStep = .installation

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    /// Starts the steps by installing the Jetpack plugin.
    ///
    func startInstallation() {
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

    private func checkSiteConnection() {
        // TODO:
    }
}

private extension JetpackInstallStepsViewModel {
    enum Constants {
        static let jetpackSlug: String = "jetpack"
        static let jetpackPluginName: String = "jetpack/jetpack"
    }
}
