public enum HTTPStatusClassification {
    /// Sentinel for transport-level failures (no HTTP response: dropped
    /// connection, DNS, timeout). Mapped to the network error kind so the
    /// retry policy treats it like a 5xx instead of a hard error.
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
