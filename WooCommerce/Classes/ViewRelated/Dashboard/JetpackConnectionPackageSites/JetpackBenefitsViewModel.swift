import Experiments
import Foundation

/// View model for `JetpackBenefitsView`
///
final class JetpackBenefitsViewModel {
    /// Whether the view is showing benefits for a JetpackCP site or non-Jetpack site.
    let isJetpackCPSite: Bool

    /// Whether Jetpack install is not supported natively
    let shouldShowWebViewForJetpackInstall: Bool

    /// URL to install Jetpack in wp-admin
    let wpAdminInstallURL: URL?

    init(siteURL: String,
         isJetpackCPSite: Bool,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.isJetpackCPSite = isJetpackCPSite
        self.wpAdminInstallURL = URL(string: String(format: Constants.jetpackInstallString, siteURL))
        self.shouldShowWebViewForJetpackInstall = !isJetpackCPSite && featureFlagService.isFeatureFlagEnabled(.jetpackSetupWithApplicationPassword) == false
    }
}

extension JetpackBenefitsViewModel {

    private enum Constants {
        static let jetpackInstallString = "https://wordpress.com/jetpack/connect?url=%@&from=mobile"
    }
}
