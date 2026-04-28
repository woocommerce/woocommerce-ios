import Foundation
@testable import WooAIAssistant

/// Path-keyed stub so resolver tests can dispatch multiple families in
/// parallel and remain deterministic regardless of `withTaskGroup` ordering.
actor StubbedWCRESTClient: WCRESTClient {
    private var routes: [String: WCRESTResponse] = [:]
    private var fallback: WCRESTResponse = WCRESTResponse(data: Data(), statusCode: 404)
    private(set) var calls: [String] = []

    func stub(path: String, response: WCRESTResponse) {
        routes[path] = response
    }

    func stub(method: String, path: String, response: WCRESTResponse) {
        routes["\(method) \(path)"] = response
    }

    func setFallback(_ response: WCRESTResponse) {
        fallback = response
    }

    func request(method: String,
                 path: String,
                 query: [String: String]?,
                 body: Data?) async -> WCRESTResponse {
        calls.append(path)
        return routes["\(method) \(path)"]
            ?? routes[path]
            ?? fallback
    }
}
