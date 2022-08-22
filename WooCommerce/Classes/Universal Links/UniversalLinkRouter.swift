import Foundation
import UIKit

protocol LinkRouter {
    init(routes: [Route])
    func handle(url: URL)
}

struct UniversalLinkRouter: LinkRouter {
    private let matcher: RouteMatcher

    init(routes: [Route]) {
        matcher = RouteMatcher(routes: routes)
    }

    static let defaultRoutes: [Route] = []

    func handle(url: URL) {
        guard let matchedRoute = matcher.firstRouteMatching(url) else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return
        }

        matchedRoute.performAction()
    }
}
