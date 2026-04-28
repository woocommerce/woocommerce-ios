import Foundation
@testable import WooAIAssistant

final class RecordingWCRESTClient: WCRESTClient, @unchecked Sendable {
    struct Recorded: Equatable {
        let method: String
        let path: String
        let query: [String: String]
        let body: Data?
        let headers: [String: String]
    }

    private let lock = NSLock()
    private var responses: [WCRESTResponse]
    private var _calls: [Recorded] = []

    init(response: WCRESTResponse) {
        self.responses = [response]
    }

    init(responses: [WCRESTResponse]) {
        self.responses = responses
    }

    var calls: [Recorded] {
        lock.lock(); defer { lock.unlock() }
        return _calls
    }

    func request(method: String,
                 path: String,
                 query: [String: String]?,
                 body: Data?,
                 headers: [String: String]?) async -> WCRESTResponse {
        lock.lock()
        _calls.append(.init(method: method,
                            path: path,
                            query: query ?? [:],
                            body: body,
                            headers: headers ?? [:]))
        let response = responses.count > 1 ? responses.removeFirst() : (responses.first ?? WCRESTResponse(data: Data(), statusCode: 200))
        lock.unlock()
        return response
    }
}

enum StubResponses {
    static func ok(_ json: String) -> WCRESTResponse {
        WCRESTResponse(data: Data(json.utf8), statusCode: 200)
    }

    static func failure(statusCode: Int, body: String = "") -> WCRESTResponse {
        WCRESTResponse(data: Data(body.utf8), statusCode: statusCode)
    }
}
