import Foundation
import WebKit
import Yosemite

/// View model used for the web view controller to setup Jetpack connection during the login flow.
///
final class JetpackConnectionWebViewModel: AuthenticatedWebViewModel {
    let title: String

    let initialURL: URL?
    let siteURL: String
    let completionHandler: () -> Void
    let failureHandler: () -> Void
    let dismissalHandler: () -> Void

    private let stores: StoresManager
    private let analytics: Analytics
    private var isCompleted = false

    init(initialURL: URL,
         siteURL: String,
         title: String = Localization.title,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         completion: @escaping () -> Void,
         onFailure: @escaping () -> Void = {},
         onDismissal: @escaping () -> Void = {}) {
        self.title = title
        self.stores = stores
        self.analytics = analytics
        self.initialURL = initialURL
        self.siteURL = siteURL
        self.completionHandler = completion
        self.failureHandler = onFailure
        self.dismissalHandler = onDismissal
    }

    func handleDismissal() {
        guard isCompleted == false else {
            return
        }
        if stores.isAuthenticated == false {
            analytics.track(.loginJetpackConnectDismissed)
        }
        dismissalHandler()
    }

    func handleRedirect(for url: URL?) {
        guard let path = url?.absoluteString else {
            return
        }
        handleCompletionIfPossible(path)
    }

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        let url = navigationURL.absoluteString
        if handleCompletionIfPossible(url) {
            return .cancel
        }
        return .allow
    }

    func decidePolicy(for response: URLResponse) async -> WKNavigationResponsePolicy {
        guard let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode != 404 else {
            return .allow
        }
        await MainActor.run { [weak self] in
            self?.failureHandler()
        }
        return .cancel
    }

    private func handleSetupCompletion() {
        isCompleted = true
        if stores.isAuthenticated == false {
            analytics.track(.loginJetpackConnectCompleted)
        }
        completionHandler()
    }

    @discardableResult
    func handleCompletionIfPossible(_ url: String) -> Bool {
        // When the web view navigates to the mobile redirect URL or Jetpack plans page,
        // we can assume that the setup has completed.
        let isMobileRedirect = url.hasPrefix(Constants.mobileRedirectURL)
        let isPlansPage = url.hasPrefix(Constants.plansPage)
        if isMobileRedirect || isPlansPage {
            // Running on the main thread is necessary if this method is triggered from `decidePolicy`.
            DispatchQueue.main.async { [weak self] in
                self?.handleSetupCompletion()
            }
            return true
        }
        return false
    }
}

private extension JetpackConnectionWebViewModel {
    enum Constants {
        static let mobileRedirectURL = "woocommerce://jetpack-connected"
        static let plansPage = "https://wordpress.com/jetpack/connect/plans"
    }

    enum Localization {
        static let title = NSLocalizedString("Connect Jetpack", comment: "Title of the Jetpack connection web view in the login flow")
    }
}
