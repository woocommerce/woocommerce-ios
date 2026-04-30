public enum HTTPStatusClassification {
    /// Sentinel for transport-level failures: no HTTP response (dropped connection, DNS, timeout).
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
        case 500..<600:
            return .upstreamFailure
        default:
            return .unknown
        }
    }

    /// True when the write may or may not have landed upstream. `transportFailure` covers
    /// both pre-send and mid-body drops which we cannot distinguish here, so writes treat
    /// both as outcome_unknown to avoid retry-induced duplicates.
    public static func isOutcomeUnknownStatus(_ statusCode: Int) -> Bool {
        statusCode == transportFailure || statusCode == 408
    }
}
