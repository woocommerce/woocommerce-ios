import Foundation
import Combine

extension UniversalLinkRouter {
    static func justInTimeMessagesUniversalLinkRouter(tabBarController: MainTabBarController?,
                                                      urlOpener: URLOpener) -> UniversalLinkRouter {
        UniversalLinkRouter(routes: Self.defaultRoutes(tabBarController: tabBarController),
                            bouncingURLOpener: urlOpener,
                            analyticsTracker: nil)
    }
}

struct JustInTimeMessagesURLOpener: URLOpener {
    let navigationTitle: String
    var showWebViewSheetSubject: PassthroughSubject<WebViewSheetViewModel?, Never>

    func open(_ url: URL) {
        let webViewModel = WebViewSheetViewModel(
            url: url,
            navigationTitle: navigationTitle,
            authenticated: needsAuthenticatedWebView(url: url))
        showWebViewSheetSubject.send(webViewModel)
    }
}

private extension JustInTimeMessagesURLOpener {
    func needsAuthenticatedWebView(url: URL) -> Bool {
        guard let host = url.host else {
            return false
        }
        return Constants.trustedDomains.contains(host)
    }

    enum Constants {
        static let trustedDomains = ["woocommerce.com", "wordpress.com"]
    }
}
