import Foundation
@testable import WooAIAssistant

/// Path-keyed stub so resolver tests can dispatch multiple families in
/// parallel and remain deterministic regardless of `withTaskGroup` ordering.
final class StubbedWCRESTClient: WCRESTClient, @unchecked Sendable {
    private let lock = NSLock()
    private var routes: [String: WCRESTResponse] = [:]
    private var fallback: WCRESTResponse = WCRESTResponse(data: Data(), statusCode: 404)
    private var _calls: [String] = []

    var calls: [String] {
        lock.lock(); defer { lock.unlock() }
        return _calls
    }

    func stub(path: String, response: WCRESTResponse) {
        lock.lock(); defer { lock.unlock() }
        routes[path] = response
    }

    func stub(method: String, path: String, response: WCRESTResponse) {
        lock.lock(); defer { lock.unlock() }
        routes["\(method) \(path)"] = response
    }

    func setFallback(_ response: WCRESTResponse) {
        lock.lock(); defer { lock.unlock() }
        fallback = response
    }

    func request(method: String,
                 path: String,
                 query: [String: String]?,
                 body: Data?,
                 headers: [String: String]?) async -> WCRESTResponse {
        lock.lock()
        _calls.append(path)
        let response = routes["\(method) \(path)"]
            ?? routes[path]
            ?? fallback
        lock.unlock()
        return response
    }
}
