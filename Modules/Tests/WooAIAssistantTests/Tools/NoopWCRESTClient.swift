import Foundation
@testable import WooAIAssistant

struct NoopWCRESTClient: WCRESTClient {
    func request(method: String,
                 path: String,
                 query: [String: String]?,
                 body: Data?) async -> WCRESTResponse {
        WCRESTResponse(data: Data(), statusCode: 200)
    }
}
