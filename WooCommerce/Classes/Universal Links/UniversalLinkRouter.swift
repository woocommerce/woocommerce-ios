import Foundation
import UIKit
import protocol WooFoundation.Analytics

/// Keeps a list of possible URL routes that are exposed
/// via universal links, and handles incoming links to trigger the appropriate route.
///
struct UniversalLinkRouter {
    private let matcher: RouteMatcher
    private let bouncingURLOpener: URLOpener
    private let analyticsTracker: UniversalLinkRouterAnalyticsTracking?
    private let routes: [Route]

    /// The order of the passed Route array matters, as given two routes that handle a path only the first
    /// will be called to perform its action. If no route matches the path it uses the `bouncingURLOpener` to
    /// open it e.g to be opened in web when the app cannot handle the link
    ///
    init(routes: [Route],
         bouncingURLOpener: URLOpener = ApplicationURLOpener(),
         analyticsTracker: UniversalLinkRouterAnalyticsTracking? = UniversalLinkAnalyticsTracker(analytics: ServiceLocator.analytics)) {
        matcher = RouteMatcher(routes: routes)
        self.routes = routes
        self.bouncingURLOpener = bouncingURLOpener
        self.analyticsTracker = analyticsTracker
    }

    /// Checks if any of the routes can handle the url
    func canHandle(url: URL) -> Bool {
        return canHandle(subPath: url.lastPathComponent)
    }

    /// Checks if any of the routes can handle the subPath
    func canHandle(subPath: String) -> Bool {
        for route in routes {
            if route.canHandle(subPath: subPath) {
                return true
            }
        }
        return false
    }

    static func defaultUniversalLinkRouter(tabBarController: MainTabBarController) -> UniversalLinkRouter {
        UniversalLinkRouter(routes: UniversalLinkRouter.defaultRoutes(navigator: tabBarController))
    }

    /// Add your route here if you want it to be considered when matching for an incoming universal link.
    /// As we only perform one action to avoid conflicts, order matters (only the first matched route will be called to perform its action)
    /// If `tabBarController: nil` is passed, some routes will not work, e.g. Payments related routes, which require the tab bar for navigation.
    ///
    static func defaultRoutes(navigator: DeepLinkNavigator?) -> [Route] {
        let routes: [Route] = [OrderDetailsRoute(), MyStoreRoute()]
        guard let navigator = navigator else {
            DDLogWarn("⛔️ Unable to create tab bar dependent Universal Link routes, some links will not be handled")
            return routes
        }
        return routes + [PaymentsRoute(deepLinkNavigator: navigator),
                         OrdersRoute(deepLinkNavigator: navigator)]
    }

    func handle(url: URL) {
        guard let matchedRoute = matcher.firstRouteMatching(url),
              matchedRoute.performAction() else {
            analyticsTracker?.trackUniversalLinkFailure(url: url)
            return bouncingURLOpener.open(url)
        }

        analyticsTracker?.trackUniversalLinkOpened(subPath: matchedRoute.subPath)
    }
}

protocol UniversalLinkRouterAnalyticsTracking {
    func trackUniversalLinkFailure(url: URL)
    func trackUniversalLinkOpened(subPath: String)
}

struct UniversalLinkAnalyticsTracker: UniversalLinkRouterAnalyticsTracking {
    let analytics: Analytics

    func trackUniversalLinkFailure(url: URL) {
        analytics.track(event: WooAnalyticsEvent.universalLinkFailed(with: url))
    }

    func trackUniversalLinkOpened(subPath: String) {
        analytics.track(event: WooAnalyticsEvent.universalLinkOpened(with: subPath))
    }
}
