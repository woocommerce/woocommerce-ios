import AutomatticTracks
import Sentry
import Storage

/// Logs crashes/messages to Sentry.
final class SentryCrashLogger: CrashLogger {
    func logMessage(_ message: String, properties: [String: Any]?, level: SeverityLevel) {
        CrashLogging.logMessage(message, properties: properties?.serializeValuesForLoggingIfNeeded(), level: SentrySeverity(level: level))
    }
}

private extension SentrySeverity {
    init(level: SeverityLevel) {
        switch level {
        case .fatal:
            self = .fatal
        case .error:
            self = .error
        case .warning:
            self = .warning
        case .info:
            self = .info
        case .debug:
            self = .debug
        }
    }
}
