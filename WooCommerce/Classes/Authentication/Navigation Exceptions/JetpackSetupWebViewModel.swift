import Foundation
import WebKit

/// View model used for the web view controller to install Jetpack the plugin during the login flow.
///
final class JetpackSetupWebViewModel: PluginSetupWebViewModel {

    /// The site URL to set up Jetpack for.
    private let siteURL: String
    private let analytics: Analytics

    /// The closure to trigger when Jetpack setup completes.
    private let completionHandler: (String?) -> Void

    /// The email address that the user uses to authorize Jetpack
    private var authorizedEmailAddress: String?

    init(siteURL: String, analytics: Analytics = ServiceLocator.analytics, onCompletion: @escaping (String?) -> Void) {
        self.siteURL = siteURL
        self.analytics = analytics
        self.completionHandler = onCompletion
    }

    // MARK: - `PluginSetupWebViewModel` conformance
    let title = Localization.title

    var initialURL: URL? {
        guard let escapedSiteURL = siteURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: String(format: Constants.jetpackInstallString, escapedSiteURL, Constants.mobileRedirectURL)) else {
            return nil
        }
        return url
    }

    func handleDismissal() {
        analytics.track(event: .LoginJetpackSetup.setupDismissed(source: .web))
    }

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        let url = navigationURL.absoluteString
        switch url {
        // When the web view is about to navigate to the redirect URL for mobile, we can assume that the setup has completed.
        case Constants.mobileRedirectURL:
            handleSetupCompletion()
            return .cancel
        default:
            if let match = JetpackSetupWebStep.matchingStep(for: url) {
                analytics.track(event: .LoginJetpackSetup.setupFlow(source: .web, step: match.trackingStep))
            } else if url.hasPrefix(Constants.jetpackAuthorizeURL) {
                authorizedEmailAddress = getQueryStringParameter(url: url, param: Constants.userEmailParam)
            }
            return .allow
        }
    }
}

private extension JetpackSetupWebViewModel {

    func handleSetupCompletion() {
        analytics.track(event: .LoginJetpackSetup.setupCompleted(source: .web))
        completionHandler(authorizedEmailAddress)
    }

    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else {
            return nil
        }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }

    enum Constants {
        static let jetpackInstallString = "https://wordpress.com/jetpack/connect?url=%@&mobile_redirect=%@&from=mobile"
        static let mobileRedirectURL = "woocommerce://jetpack-connected"
        static let jetpackAuthorizeURL = "https://jetpack.wordpress.com/jetpack.authorize"
        static let userEmailParam = "user_email"
    }

    enum JetpackSetupWebStep: CaseIterable {
        case automaticInstall
        case wpcomLogin
        case authorize
        case siteLogin
        case pluginDetail
        case pluginInstallation
        case pluginActivation
        case pluginSetup

        var path: String {
            switch self {
            case .automaticInstall:
                return "https://wordpress.com/jetpack/connect/install"
            case .wpcomLogin:
                return "https://wordpress.com/log-in/jetpack"
            case .authorize:
                return "https://wordpress.com/jetpack/connect/authorize"
            case .siteLogin:
                return "wp-admin/wp-login.php"
            case .pluginDetail:
                return "wp-admin/plugin-install.php"
            case .pluginInstallation:
                return "wp-admin/update.php?action=install-plugin"
            case .pluginActivation:
                return "wp-admin/plugins.php?action=activate"
            case .pluginSetup:
                return "wp-admin/admin.php?page=jetpack"
            }
        }

        var trackingStep: WooAnalyticsEvent.LoginJetpackSetup.Step {
            switch self {
            case .automaticInstall: return .automaticInstall
            case .wpcomLogin: return .wpcomLogin
            case .authorize: return .authorize
            case .siteLogin: return .siteLogin
            case .pluginDetail: return .pluginDetail
            case .pluginInstallation: return .pluginInstallation
            case .pluginActivation: return .pluginActivation
            case .pluginSetup: return .pluginSetup
            }
        }

        static func matchingStep(for url: String) -> Self? {
            Self.allCases.first { step in
                url.contains(step.path)
            }
        }
    }

    enum Localization {
        static let title = NSLocalizedString("Jetpack Setup", comment: "Title of the Jetpack Setup screen")
    }
}
