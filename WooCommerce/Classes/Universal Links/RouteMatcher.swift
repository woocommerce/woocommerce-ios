import Foundation

struct MatchedRoute {
    private let route: Route
    private let parameters: [String: String]

    func performAction() {
    }
}

class RouteMatcher {
    let routes: [Route]

    /// - parameter routes: A collection of routes to match against.
    init(routes: [Route]) {
        self.routes = routes
    }

    func firstRouteMatching(_ url: URL) -> MatchedRoute? {
        return nil
    }
}
