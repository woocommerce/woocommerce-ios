import Foundation
@testable import WooAIAssistant

actor MockWCRESTClient: WCRESTClient {
    struct Recorded: Equatable {
        let method: String
        let path: String
        let query: [String: String]
        let body: Data?
        let headers: [String: String]
    }

    private(set) var calls: [Recorded] = []
    private var responses: [WCRESTResponse]

    init(response: WCRESTResponse) {
        self.responses = [response]
    }

    init(responses: [WCRESTResponse]) {
        self.responses = responses
    }

    func request(method: String,
                 path: String,
                 query: [String: String]?,
                 body: Data?,
                 headers: [String: String]?) async -> WCRESTResponse {
        calls.append(.init(method: method,
                           path: path,
                           query: query ?? [:],
                           body: body,
                           headers: headers ?? [:]))
        return responses.count > 1 ? responses.removeFirst() : (responses.first ?? WCRESTResponse(data: Data(), statusCode: 200))
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
