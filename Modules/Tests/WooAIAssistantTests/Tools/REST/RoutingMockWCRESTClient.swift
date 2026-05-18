import Foundation
@testable import WooAIAssistant

actor RoutingMockWCRESTClient: WCRESTClient {
    struct Recorded: Equatable {
        let method: String
        let path: String
        let query: [String: String]
        let body: Data?
    }

    private(set) var calls: [Recorded] = []
    private let routes: [String: WCRESTResponse]
    private let fallback: WCRESTResponse

    init(routes: [String: WCRESTResponse], fallback: WCRESTResponse = WCRESTResponse(data: Data(), statusCode: 404)) {
        self.routes = routes
        self.fallback = fallback
    }

    func request(method: String,
                 path: String,
                 query: [String: String]?,
                 body: Data?) async -> WCRESTResponse {
        calls.append(.init(method: method, path: path, query: query ?? [:], body: body))
        return routes["\(method) \(path)"] ?? fallback
    }
}
