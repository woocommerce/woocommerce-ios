import Foundation
@testable import WooAIAssistant

actor SyncStubWCRESTClient: WCRESTClient {

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
                 body: Data?) async -> WCRESTResponse {
        if responses.count > 1 {
            return responses.removeFirst()
        }
        return responses.first ?? WCRESTResponse(data: Data(), statusCode: 200)
    }
}
