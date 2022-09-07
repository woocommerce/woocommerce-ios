import Foundation
import WebKit

/// View model used for the web view controller to setup Jetpack connection during the login flow.
///
final class JetpackConnectionWebViewModel: AuthenticatedWebViewModel {
    let title = Localization.title

    let initialURL: URL?
    let siteURL: String
    let completionHandler: () -> Void

    init(initialURL: URL, siteURL: String, completion: @escaping () -> Void) {
        self.initialURL = initialURL
        self.siteURL = siteURL
        self.completionHandler = completion
    }

    func handleDismissal() {
        // TODO: tracks?
    }

    func handleRedirect(for url: URL?) {
        // No-op
    }

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        let url = navigationURL.absoluteString
        switch url {
        // When the web view is about to navigate to the site address, we can assume that the setup has completed.
        case let url where url.hasPrefix(siteURL) || url.hasPrefix(Constants.plansPage):
            await MainActor.run { [weak self] in
                self?.handleSetupCompletion()
            }
            return .cancel
        default:
            return .allow
        }
    }

    private func handleSetupCompletion() {
        // TODO: tracks?
        completionHandler()
    }
}

private extension JetpackConnectionWebViewModel {
    enum Constants {
        static let plansPage = "https://wordpress.com/jetpack/connect/plans"
    }

    enum Localization {
        static let title = NSLocalizedString("Connect Jetpack", comment: "Title of the Jetpack connection web view in the login flow")
    }
}
