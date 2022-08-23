import Foundation
import UIKit

/// Keeps a list of possible URL routes that are exposed
/// via universal links, and handles incoming links to trigger the appropriate route.
///
struct UniversalLinkRouter {
    private let matcher: RouteMatcher

    /// The order of the passed Route array matters, as given two routes that handle a path only the first
    /// will be called to perform its action
    ///
    init(routes: [Route]) {
        matcher = RouteMatcher(routes: routes)
    }

    static let defaultRoutes: [Route] = [
        OrderDetailsRoute()
    ]

    func handle(url: URL) {
        guard let matchedRoute = matcher.firstRouteMatching(url) else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return
        }

        matchedRoute.performAction()
    }
}
