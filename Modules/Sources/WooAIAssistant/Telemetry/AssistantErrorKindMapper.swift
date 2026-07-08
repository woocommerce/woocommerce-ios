import Foundation

public enum AssistantErrorKindMapper {

    public static func map(_ error: AssistantError) -> AssistantTelemetryErrorKind {
        if let mapped = mapByKind(error.kind) {
            return mapped
        }
        return mapByHTTPCode(error.code) ?? .unknown
    }

    private static func mapByKind(_ kind: AssistantErrorKind) -> AssistantTelemetryErrorKind? {
        switch kind {
        case .network:
            return .network
        case .auth:
            return .auth
        case .rateLimit:
            return .rateLimited
        case .timeout:
            return .timeout
        case .upstreamFailure, .invalidStream, .toolFailed:
            return .serverError
        case .invalidToolCall:
            return .validationError
        case .cancelled:
            return .cancelled
        case .outcomeUnknown, .unknown:
            return nil
        }
    }

    private static func mapByHTTPCode(_ code: String?) -> AssistantTelemetryErrorKind? {
        guard let code, let status = Int(code) else { return nil }
        switch status {
        case 401, 403:
            return .auth
        case 408, 504:
            return .timeout
        case 429:
            return .rateLimited
        case 400, 422:
            return .validationError
        case 500...599:
            return .serverError
        default:
            return nil
        }
    }
}
