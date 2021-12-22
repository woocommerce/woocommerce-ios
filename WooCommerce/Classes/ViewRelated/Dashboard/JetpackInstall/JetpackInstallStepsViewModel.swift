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

    /// Error occurred in any install step
    ///
    private var installError: Error?

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    /// Starts the steps by checking Jetpack-the-plugin.
    ///
    func startInstallation() {
        checkJetpackPluginDetailsAndProceed()
    }

    /// Checks Jetpack plugin details without installing the plugin.
    /// If the plugin is active, proceed to check site connection, otherwise do nothing.
    ///
    func checkJetpackPluginDetails() {
        let pluginInfoAction = SitePluginAction.getPluginDetails(siteID: siteID, pluginName: Constants.jetpackPluginName) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let plugin):
                if plugin.status == .active {
                    self.checkSiteConnection()
                }
            case .failure:
                break
            }
        }
        stores.dispatch(pluginInfoAction)
    }

    /// Fetches details for Jetpack-the-plugin, and installs it if the plugin does not exist.
    /// Otherwise proceeds to activate the plugin if needed.
    /// - Parameters:
    ///   - retryCount: number of retries done for error handling.
    ///
    private func checkJetpackPluginDetailsAndProceed() {
        guard retryCount <= Constants.maxRetryCount else {
            installFailed = true
            ServiceLocator.analytics.track(.jetpackInstallFailed, properties: nil, error: installError)
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
            case .failure(let error):
                // plugin is likely to not have been installed, so proceed to install it.
                self.installJetpackPlugin()
                self.installError = error
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
            case .failure(let error):
                self.installError = error
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
            case .failure(let error):
                self.installError = error
                self.retryCount += 1
                self.checkJetpackPluginDetailsAndProceed()
            }
        }
        stores.dispatch(activationAction)
    }

    /// Check site to make sure connection succeeds.
    ///
    func checkSiteConnection() {
        installFailed = false
        currentStep = .connection
        let siteFetch = AccountAction.loadAndSynchronizeSite(siteID: siteID,
                                                             forcedUpdate: true,
                                                             isJetpackConnectionPackageSupported: true) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let site):
                guard site.isWooCommerceActive, !site.isJetpackCPConnected else {
                    self.retryCount += 1
                    self.checkJetpackPluginDetailsAndProceed()
                    return
                }
                self.currentStep = .done
                self.retryCount = 0
                self.stores.updateDefaultStore(site)
                ServiceLocator.analytics.track(.jetpackInstallSucceeded)
            case .failure(let error):
                self.installError = error
                self.retryCount += 1
                self.checkJetpackPluginDetailsAndProceed()
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
