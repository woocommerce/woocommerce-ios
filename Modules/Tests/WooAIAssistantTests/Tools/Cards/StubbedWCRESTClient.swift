import Foundation
@testable import WooAIAssistant

/// Path-keyed stub so resolver tests can dispatch multiple families in
/// parallel and remain deterministic regardless of `withTaskGroup` ordering.
actor StubbedWCRESTClient: WCRESTClient {
    private var routes: [String: WCRESTResponse] = [:]
    private(set) var calls: [String] = []

    func stub(path: String, response: WCRESTResponse) {
        routes[path] = response
    }

    func request(method: String,
                 path: String,
                 query: [String: String]?,
                 body: Data?) async -> WCRESTResponse {
        calls.append(path)
        return routes[path] ?? WCRESTResponse(data: Data(), statusCode: 404)
    }
}
