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

    static let defaultRoutes: [Route] = [
        OrderDetailsRoute()
    ]

    func handle(url: URL) {
        guard let matchedRoute = matcher.firstRouteMatching(url) else {
            return bouncingURLOpener.open(url)
        }

        matchedRoute.performAction()
    }
}
