import Foundation
import UIKit

/// Keeps a list of possible URL routes that are exposed
/// via universal links, and handles incoming links to trigger the appropriate route.
///
struct UniversalLinkRouter {
    private let matcher: RouteMatcher
    private let bouncingURLOpener: URLOpener

    /// The order of the passed Route array matters, as given two routes that handle a path only the first
    /// will be called to perform its action. If no route matches the path it uses the `bouncingURLOpener` to
    /// open it e.g to be opened in web when the app cannot handle the link
    ///
    init(routes: [Route], bouncingURLOpener: URLOpener = ApplicationURLOpener()) {
        matcher = RouteMatcher(routes: routes)
        self.bouncingURLOpener = bouncingURLOpener
    }

    static func defaultUniversalLinkRouter(tabBarController: MainTabBarController) -> UniversalLinkRouter {
        UniversalLinkRouter(routes: UniversalLinkRouter.defaultRoutes(tabBarController: tabBarController))
    }

    /// Add your route here if you want it to be considered when matching for an incoming universal link.
    /// As we only perform one action to avoid conflicts, order matters (only the first matched route will be called to perform its action)
    ///
    private static func defaultRoutes(tabBarController: MainTabBarController) -> [Route] {
        return [OrderDetailsRoute(), PaymentsRoute(tabBarController: tabBarController)]
    }

    func handle(url: URL) {
        guard let matchedRoute = matcher.firstRouteMatching(url),
              matchedRoute.performAction() else {
            ServiceLocator.analytics.track(event: WooAnalyticsEvent.universalLinkFailed(with: url))
            return bouncingURLOpener.open(url)
        }

        ServiceLocator.analytics.track(event: WooAnalyticsEvent.universalLinkOpened(with: matchedRoute.subPath))
    }
}
