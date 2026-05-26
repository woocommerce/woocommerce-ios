import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct WCRESTClientRetryTests {
    @Test
    func test_request_when_5xx_then_retries_twice_then_returns_transportError() async {
        // Given
        let stub = StubWCRESTClient(responses: [
            .status(503),
            .status(503),
            .status(503)
        ])
        let recorder = SleepRecorder()
        let client = RetryingWCRESTClient(inner: stub,
                                          policy: .default,
                                          sleep: recorder.record)

        // When
        let response = await client.request(method: "GET",
                                            path: "wc/v3/orders",
                                            query: nil,
                                            body: nil)

        // Then
        #expect(response.statusCode == 503)
        #expect(await stub.callCount == 3)
        #expect(await recorder.delays == [0.2, 0.8])
        #expect(HTTPStatusClassification.errorKind(forStatusCode: response.statusCode) == .upstreamFailure)
    }

    @Test
    func test_request_when_other_4xx_then_does_not_retry_and_kind_is_unknown() async {
        // Given
        let stub = StubWCRESTClient(responses: [.status(404)])
        let recorder = SleepRecorder()
        let client = RetryingWCRESTClient(inner: stub,
                                          policy: .default,
                                          sleep: recorder.record)

        // When
        let response = await client.request(method: "GET",
                                            path: "wc/v3/orders/9999",
                                            query: nil,
                                            body: nil)

        // Then
        #expect(response.statusCode == 404)
        #expect(await stub.callCount == 1)
        #expect(await recorder.delays.isEmpty)
        #expect(HTTPStatusClassification.errorKind(forStatusCode: response.statusCode) == .unknown)
    }

    @Test
    func test_request_when_401_then_kind_is_auth() async {
        // Given
        let stub = StubWCRESTClient(responses: [.status(401)])
        let client = RetryingWCRESTClient(inner: stub,
                                          policy: .default,
                                          sleep: { _ in })

        // When
        let response = await client.request(method: "GET",
                                            path: "wc/v3/orders",
                                            query: nil,
                                            body: nil)

        // Then
        #expect(response.statusCode == 401)
        #expect(await stub.callCount == 1)
        #expect(HTTPStatusClassification.errorKind(forStatusCode: response.statusCode) == .auth)
    }

    @Test
    func test_request_when_429_then_retries_and_kind_is_rateLimit() async {
        // Given
        let stub = StubWCRESTClient(responses: [
            .status(429),
            .status(200)
        ])
        let recorder = SleepRecorder()
        let client = RetryingWCRESTClient(inner: stub,
                                          policy: .default,
                                          sleep: recorder.record)

        // When
        let response = await client.request(method: "GET",
                                            path: "wc/v3/orders",
                                            query: nil,
                                            body: nil)

        // Then
        #expect(response.statusCode == 200)
        #expect(await stub.callCount == 2)
        #expect(await recorder.delays == [0.2])
        #expect(HTTPStatusClassification.errorKind(forStatusCode: 429) == .rateLimit)
    }

    @Test
    func test_request_when_post_returns_5xx_then_does_not_retry() async {
        // Given
        let stub = StubWCRESTClient(responses: [.status(503)])
        let recorder = SleepRecorder()
        let client = RetryingWCRESTClient(inner: stub,
                                          policy: .default,
                                          sleep: recorder.record)

        // When
        let response = await client.request(method: "POST",
                                            path: "wc/v3/orders/3551",
                                            query: nil,
                                            body: Data("{}".utf8))

        // Then
        #expect(response.statusCode == 503)
        #expect(await stub.callCount == 1)
        #expect(await recorder.delays.isEmpty)
    }

    @Test
    func test_request_when_transport_failure_then_retries_then_succeeds() async {
        // Given
        let stub = StubWCRESTClient(responses: [
            .status(HTTPStatusClassification.transportFailure),
            .status(200)
        ])
        let recorder = SleepRecorder()
        let client = RetryingWCRESTClient(inner: stub,
                                          policy: .default,
                                          sleep: recorder.record)

        // When
        let response = await client.request(method: "GET",
                                            path: "wc/v3/orders",
                                            query: nil,
                                            body: nil)

        // Then
        #expect(response.statusCode == 200)
        #expect(await stub.callCount == 2)
        #expect(await recorder.delays == [0.2])
    }

    @Test
    func test_request_when_sleep_throws_cancellation_then_returns_transport_failure() async {
        // Given
        let stub = StubWCRESTClient(responses: [
            .status(503),
            .status(200)
        ])
        let client = RetryingWCRESTClient(inner: stub,
                                          policy: RESTRetryPolicy(maxRetries: 2, backoff: [60, 60]),
                                          sleep: { _ in throw CancellationError() })

        // When
        let response = await client.request(method: "GET",
                                            path: "wc/v3/orders",
                                            query: nil,
                                            body: nil)

        // Then
        #expect(response.statusCode == HTTPStatusClassification.transportFailure)
        #expect(await stub.callCount == 1)
    }
}

// MARK: - Test doubles

private actor StubWCRESTClient: WCRESTClient {
    enum Scripted {
        case status(Int)
        case response(WCRESTResponse)
    }

    private var responses: [Scripted]
    private(set) var callCount = 0

    init(responses: [Scripted]) {
        self.responses = responses
    }

    func request(method: String,
                 path: String,
                 query: [String: String]?,
                 body: Data?) async -> WCRESTResponse {
        callCount += 1
        let scripted = responses.isEmpty ? .status(500) : responses.removeFirst()
        switch scripted {
        case .status(let code):
            return WCRESTResponse(data: Data(), statusCode: code)
        case .response(let response):
            return response
        }
    }
}

private actor SleepRecorder {
    private(set) var delays: [TimeInterval] = []

    func record(_ interval: TimeInterval) async throws {
        delays.append(interval)
    }
}
