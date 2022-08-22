import Foundation

struct MatchedRoute {
    let route: Route
    let parameters: [String: String]

    func performAction() {
        route.action.perform(with: parameters)
    }
}

class RouteMatcher {
    let routes: [Route]

    /// - parameter routes: A collection of routes to match against.
    init(routes: [Route]) {
        self.routes = routes
    }

    func firstRouteMatching(_ url: URL) -> MatchedRoute? {
        guard let components = URLComponents(string: url.absoluteString),
              let firstRoute = routes.first(where: { $0.path == components.path }) else {
            return nil
        }

        guard let queryItems = components.queryItems else {
            return MatchedRoute(route: firstRoute, parameters: [:])
        }

        return MatchedRoute(route: firstRoute, parameters: parameters(from: queryItems))
    }
}

private extension RouteMatcher {
    func parameters(from queryItems: [URLQueryItem]) -> [String: String] {
        var parameters: [String: String] = [:]
        for queryItem in queryItems {
            guard let value = queryItem.value else {
                continue
            }

            parameters[queryItem.name] = value
        }

        return parameters
    }
}
