import Foundation
import Synchronization
@testable import NetworkingCore

/// Stands in for `URLSession` in discovery and application-password tests.
///
/// The discovery tests call it from concurrent tasks, so its state is guarded by a lock.
///
final class MockURLSession: URLSessionProtocol, Sendable {
    private struct State {
        var responses: [String: (Data, URLResponse)] = [:]
        var errors: [String: Error] = [:]
        var lastRequest: URLRequest?
        var requestCount = 0
    }

    private let state = Mutex(State())

    var lastRequest: URLRequest? {
        state.withLock { $0.lastRequest }
    }

    var requestCount: Int {
        state.withLock { $0.requestCount }
    }

    /// The stubbed responses registered so far, keyed by URL.
    var responses: [String: (Data, URLResponse)] {
        state.withLock { $0.responses }
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let key = request.url?.absoluteString ?? ""
        let (stubbedError, stubbedResponse) = state.withLock { state -> (Error?, (Data, URLResponse)?) in
            state.lastRequest = request
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

    func reset() {
        state.withLock { $0 = State() }
    }
}
