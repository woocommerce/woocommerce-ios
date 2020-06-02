import AutomatticTracks
import Sentry
import Storage

/// Logs crashes/messages to Sentry.
final class SentryCrashLogger: CrashLogger {
    func logMessage(_ message: String, properties: [String: Any]?, level: SeverityLevel) {
        CrashLogging.logMessage(message, properties: properties?.serializeValuesForLoggingIfNeeded(), level: SentrySeverity(level: level))
    }

    func logMessageAndWait(_ message: String, properties: [String: Any]?, level: SeverityLevel) {
        CrashLogging.logMessageAndWait(message, properties: properties?.serializeValuesForLoggingIfNeeded(), level: SentrySeverity(level: level))
    }
}

private extension CrashLogging {
    /**
     Mostly similar to `logMessage(_:properties:level:)`, but this function blocks the thread until the event is fired.
     - Parameters:
     - message: The message
     - properties: A dictionary containing additional information about this error
     - level: The level of severity to report in Sentry
    */
    static func logMessageAndWait(_ message: String, properties: [String: Any]?, level: SentrySeverity) {
        let event = Event(level: level)
        event.message = message
        event.extra = properties

        Client.shared?.snapshotStacktrace {
            Client.shared?.appendStacktrace(to: event)
        }

        guard let client = Client.shared else {
           return
        }

        let semaphore = DispatchSemaphore(value: 0)

        client.send(event: event) { _ in
            semaphore.signal()
        }

        semaphore.wait()
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
