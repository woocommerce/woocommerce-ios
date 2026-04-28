import Foundation

/// Writes (POST, PUT, PATCH) never auto-retry. A duplicate write reaching the
/// upstream could double-charge or duplicate inventory mutations, and the
/// runtime can't tell whether the first attempt landed when the transport
/// drops mid-flight.
public struct RESTRetryPolicy: Sendable, Equatable {
    public let maxRetries: Int
    public let backoff: [TimeInterval]

    public init(maxRetries: Int = 2,
                backoff: [TimeInterval] = [0.2, 0.8]) {
        self.maxRetries = maxRetries
        self.backoff = backoff
    }

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
