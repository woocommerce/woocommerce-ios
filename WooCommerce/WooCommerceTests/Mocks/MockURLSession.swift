import Foundation
import Synchronization
import protocol NetworkingCore.URLSessionProtocol

final class MockURLSession: URLSessionProtocol {
    private struct State {
        var responses: [String: (Data, URLResponse)] = [:]
        var errors: [String: Error] = [:]
        var lastRequest: URLRequest?
        var receivedRequests: [URLRequest] = []
        var requestCount = 0
    }

    // Setup and assertions can run on a different executor from URLSessionProtocol.data(for:).
    private let state = Mutex(State())

    var responses: [String: (Data, URLResponse)] {
        get { state.withLock { $0.responses } }
        set { state.withLock { $0.responses = newValue } }
    }

    var errors: [String: Error] {
        get { state.withLock { $0.errors } }
        set { state.withLock { $0.errors = newValue } }
    }

    var lastRequest: URLRequest? {
        state.withLock { $0.lastRequest }
    }

    var receivedRequests: [URLRequest] {
        state.withLock { $0.receivedRequests }
    }

    var requestCount: Int {
        state.withLock { $0.requestCount }
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let key = request.url?.absoluteString ?? ""
        let (stubbedError, stubbedResponse) = state.withLock { state -> (Error?, (Data, URLResponse)?) in
            state.lastRequest = request
            state.receivedRequests.append(request)
            state.requestCount += 1
            return (state.errors[key], state.responses[key])
        }

        if let stubbedError {
            throw stubbedError
        }

        if let stubbedResponse {
            return stubbedResponse
        }

        // Default success response
        let data = Data()
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }

    func simulateResponse(for url: String, data: Data = Data(), statusCode: Int = 200, headerFields: [String: String]? = nil) {
        let response = HTTPURLResponse(
            url: URL(string: url)!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headerFields
        )!
        state.withLock { $0.responses[url] = (data, response) }
    }

    func simulateError(for url: String, error: Error) {
        state.withLock { $0.errors[url] = error }
    }
}
