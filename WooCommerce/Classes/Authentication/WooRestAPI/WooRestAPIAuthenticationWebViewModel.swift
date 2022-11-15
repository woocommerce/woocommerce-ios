import Foundation
import WebKit
import Alamofire

/// View model used for the web view controller to setup Jetpack connection during the login flow.
///
final class WooRestAPIAuthenticationWebViewModel: AuthenticatedWebViewModel {
    let title = Localization.title

    let initialURL: URL? = nil

    let initialURLRequest: URLRequest?

    let siteURL: String
    let completionHandler: () -> Void

    private let analytics: Analytics

    init(siteURL: String,
         analytics: Analytics = ServiceLocator.analytics,
         completion: @escaping () -> Void) throws {
        self.analytics = analytics
        self.siteURL = siteURL
        self.completionHandler = completion

        let endPoint = "/wc-auth/v1/authorize"
        let url = siteURL + endPoint

        var request = try URLRequest(url: url.asURL(), method: .post)
        request.httpShouldHandleCookies = true

        let parameters = ["app_name": "My App Name",
                          "scope": "read_write",
                          "user_id": "User ID",
                          "return_url": Constants.returnURL,
                          "callback_url": Constants.callbackURL]

        self.initialURLRequest = try URLEncoding.default.encode(request, with: parameters)
    }

    func handleDismissal() {
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

    private func handleSetupCompletion() {
        completionHandler()
    }

    @discardableResult
    func handleCompletionIfPossible(_ url: String) -> Bool {
        if url.hasPrefix(Constants.callbackURL) {
            // Running on the main thread is necessary if this method is triggered from `decidePolicy`.
            DispatchQueue.main.async { [weak self] in
                self?.handleSetupCompletion()
            }
            return true
        }
        return false
    }
}

private extension WooRestAPIAuthenticationWebViewModel {
    enum Constants {
        static let returnURL = "https://woocommerce.com/"
        static let callbackURL = "https://wordpress.com/"
    }

    enum Localization {
        static let title = NSLocalizedString("Authorize", comment: "Title of the Jetpack connection web view in the login flow")
    }
}
