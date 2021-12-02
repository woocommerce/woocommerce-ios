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

    /// Whether the install failed. This will be observed by `JetpackInstallStepsView` to present error modal.
    ///
    @Published private(set) var installFailed: Bool = false

    /// Number of retries done for current step.
    ///
    private var retryCount: Int = 0

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    /// Starts the steps by checking Jetpack-the-plugin.
    ///
    func startInstallation() {
        checkJetpackPluginDetailsAndProceed()
    }

    /// Fetches details for Jetpack-the-plugin, and installs it if the plugin does not exist.
    /// Otherwise proceeds to activate the plugin if needed.
    /// - Parameters:
    ///   - retryCount: number of retries done for error handling.
    ///
    private func checkJetpackPluginDetailsAndProceed() {
        guard retryCount <= Constants.maxRetryCount else {
            installFailed = true
            return
        }
        let pluginInfoAction = SitePluginAction.getPluginDetails(siteID: siteID, pluginName: Constants.jetpackPluginName) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let plugin):
                if plugin.status == .active {
                    self.checkSiteConnection()
                } else {
                    self.activateJetpack()
                }
            case .failure:
                // plugin is likely to not have been installed, so proceed to install it.
                self.installJetpackPlugin()
            }
        }
        stores.dispatch(pluginInfoAction)
    }

    /// Installs Jetpack plugin to current site.
    ///
    private func installJetpackPlugin() {
        currentStep = .installation
        let installationAction = SitePluginAction.installSitePlugin(siteID: siteID, slug: Constants.jetpackSlug) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.retryCount = 0
                self.activateJetpack()
            case .failure:
                self.retryCount += 1
                self.checkJetpackPluginDetailsAndProceed()
            }
        }
        stores.dispatch(installationAction)
    }

    /// Activates the installed Jetpack plugin.
    ///
    private func activateJetpack(retryCount: Int = 0) {
        currentStep = .activation
        let activationAction = SitePluginAction.activateSitePlugin(siteID: siteID, pluginName: Constants.jetpackPluginName) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.retryCount = 0
                self.checkSiteConnection()
            case .failure:
                self.retryCount += 1
                self.checkJetpackPluginDetailsAndProceed()
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
                guard site.isWooCommerceActive, !site.isJetpackCPConnected else {
                    self.installFailed = true
                    return
                }
                self.currentStep = .done
            case .failure:
                self.installFailed = true
            }
        }
        stores.dispatch(siteFetch)
    }
}

private extension JetpackInstallStepsViewModel {
    enum Constants {
        static let jetpackSlug: String = "jetpack"
        static let jetpackPluginName: String = "jetpack/jetpack"
        static let maxRetryCount: Int = 2
    }
}
