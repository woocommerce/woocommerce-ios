import Foundation
import WebKit

/// View model used for the web view controller to setup Jetpack connection during the login flow.
///
final class JetpackConnectionWebViewModel: PluginSetupWebViewModel {
    let title = Localization.title
    
    let initialURL: URL?
    let siteURL: String
    let completionHandler: (String?) -> Void

    /// The email address that the user uses to authorize Jetpack
    private var authorizedEmailAddress: String?

    init(initialURL: URL, siteURL: String, completion: @escaping (String?) -> Void) {
        self.initialURL = initialURL
        self.siteURL = siteURL
        self.completionHandler = completion
    }
    
    func handleDismissal() {
        // TODO: tracks?
    }
    
    func handleRedirect(for url: URL?) {
        guard let path = url?.absoluteString else {
            return
        }
        print("🧭🧭 \(path)")
    }
    
    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        let url = navigationURL.absoluteString
        print("🧭 \(url)")
        switch url {
        // When the web view is about to navigate to the redirect URL for mobile, we can assume that the setup has completed.
        case let url where url.hasPrefix(siteURL):
            await MainActor.run { [weak self] in
                self?.handleSetupCompletion()
            }
            return .cancel
        default:
            if url.hasPrefix(Constants.jetpackAuthorizeURL) {
                authorizedEmailAddress = url.getQueryStringParameter(param: Constants.userEmailParam)
            }
            return .allow
        }
    }

    private func handleSetupCompletion() {
        // TODO: tracks?
        completionHandler(authorizedEmailAddress)
        
    }
}

private extension JetpackConnectionWebViewModel {
    enum Constants {
        static let jetpackAuthorizeURL = "https://jetpack.wordpress.com/jetpack.authorize"
        static let userEmailParam = "user_email"
    }

    enum Localization {
        static let title = NSLocalizedString("Connect Jetpack", comment: "Title of the Jetpack connection web view in the login flow")
    }
}
