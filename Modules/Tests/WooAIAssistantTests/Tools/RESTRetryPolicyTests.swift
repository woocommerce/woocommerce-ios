import Foundation
import Testing
@testable import WooAIAssistant

struct RESTRetryPolicyTests {
    @Test
    func test_shouldRetry_when_get_and_5xx_then_retries_until_max() {
        // Given
        let policy = RESTRetryPolicy.default

        // When / Then
        #expect(policy.shouldRetry(method: "GET", statusCode: 500, attempt: 0))
        #expect(policy.shouldRetry(method: "GET", statusCode: 502, attempt: 1))
        #expect(!policy.shouldRetry(method: "GET", statusCode: 503, attempt: 2))
    }

    @Test
    func test_shouldRetry_when_get_and_4xx_then_does_not_retry() {
        // Given
        let policy = RESTRetryPolicy.default

        // When / Then
        #expect(!policy.shouldRetry(method: "GET", statusCode: 400, attempt: 0))
        #expect(!policy.shouldRetry(method: "GET", statusCode: 401, attempt: 0))
        #expect(!policy.shouldRetry(method: "GET", statusCode: 403, attempt: 0))
        #expect(!policy.shouldRetry(method: "GET", statusCode: 404, attempt: 0))
    }

    @Test
    func test_shouldRetry_when_get_and_429_then_retries() {
        // Given
        let policy = RESTRetryPolicy.default

        // When / Then
        #expect(policy.shouldRetry(method: "GET", statusCode: 429, attempt: 0))
    }

    @Test
    func test_shouldRetry_when_post_then_never_retries() {
        // Given
        let policy = RESTRetryPolicy.default

        // When / Then
        #expect(!policy.shouldRetry(method: "POST", statusCode: 500, attempt: 0))
        #expect(!policy.shouldRetry(method: "PUT", statusCode: 503, attempt: 0))
        #expect(!policy.shouldRetry(method: "PATCH", statusCode: 429, attempt: 0))
        #expect(!policy.shouldRetry(method: "DELETE", statusCode: 502, attempt: 0))
    }

    @Test
    func test_shouldRetry_when_transport_failure_then_retries_for_idempotent_methods() {
        // Given
        let policy = RESTRetryPolicy.default
        let transport = HTTPStatusClassification.transportFailure

        // When / Then
        #expect(policy.shouldRetry(method: "GET", statusCode: transport, attempt: 0))
        #expect(!policy.shouldRetry(method: "POST", statusCode: transport, attempt: 0))
    }

    @Test
    func test_delay_returns_configured_backoff_per_attempt() {
        // Given
        let policy = RESTRetryPolicy.default

        // When / Then
        #expect(policy.delay(forAttempt: 0) == 0.2)
        #expect(policy.delay(forAttempt: 1) == 0.8)
    }
}
