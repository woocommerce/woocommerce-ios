/// Maps HTTP status codes to the assistant's typed error vocabulary so the
/// retry policy and tool executors share one classifier. Centralising the
/// mapping keeps the "what counts as auth vs upstream vs validation" rule
/// out of every tool body.
public enum HTTPStatusClassification {
    /// Sentinel used by `WCRESTClient` for transport-level failures (no HTTP
    /// response - dropped connection, DNS, timeout). Treated as retryable
    /// network kind by the policy.
    public static let transportFailure: Int = 0

    public static func isSuccess(_ statusCode: Int) -> Bool {
        (200..<300).contains(statusCode)
    }

    public static func errorKind(forStatusCode statusCode: Int) -> AssistantErrorKind {
        switch statusCode {
        case transportFailure:
            return .network
        case 401, 403:
            return .auth
        case 408:
            return .timeout
        case 429:
            return .rateLimit
        case 400..<500:
            return .invalidToolCall
        case 500..<600:
            return .upstreamFailure
        default:
            return .unknown
        }
    }
}
