import Foundation

/// Decision-only retry policy for `WCRESTClient` requests. Pure value type so
/// the policy can be unit-tested without sleeping or running networking.
///
/// Two rules drive the decision:
///   1. Transient transport faults (connection drop, 5xx, 429) are retryable.
///      4xx (except 429) and auth are not - they will not become 2xx if we
///      try again with the same payload.
///   2. Non-idempotent methods (POST, PUT, PATCH, DELETE) never auto-retry.
///      Without an idempotency key the same write reaching the upstream twice
///      would risk double-billing or duplicate inventory mutations.
public struct RESTRetryPolicy: Sendable, Equatable {
    public let maxRetries: Int
    public let backoff: [TimeInterval]

    public init(maxRetries: Int = 2,
                backoff: [TimeInterval] = [0.2, 0.8]) {
        self.maxRetries = maxRetries
        self.backoff = backoff
    }

    /// Default policy per the assistant transport spec: two retries with 200ms
    /// then 800ms backoff. Three attempts total at most.
    public static let `default` = RESTRetryPolicy()

    public func shouldRetry(method: String, statusCode: Int, attempt: Int) -> Bool {
        guard attempt < maxRetries else { return false }
        guard isIdempotent(method: method) else { return false }
        return isRetryableStatus(statusCode)
    }

    public func delay(forAttempt attempt: Int) -> TimeInterval {
        guard attempt >= 0, attempt < backoff.count else {
            return backoff.last ?? 0
        }
        return backoff[attempt]
    }

    private func isIdempotent(method: String) -> Bool {
        switch method.uppercased() {
        case "GET", "HEAD", "OPTIONS":
            return true
        default:
            return false
        }
    }

    private func isRetryableStatus(_ statusCode: Int) -> Bool {
        switch statusCode {
        case HTTPStatusClassification.transportFailure, 408, 429:
            return true
        case 500..<600:
            return true
        default:
            return false
        }
    }
}
