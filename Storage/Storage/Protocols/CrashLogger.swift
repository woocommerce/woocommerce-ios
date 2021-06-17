/// The level of severity, that is currently based on `SentrySeverity`.
public enum SeverityLevel {
    case fatal
    case error
    case warning
    case info
    case debug
}

/// Logs crashes or messages at a given severity level.
public protocol CrashLogger {
    /**
     Writes a message to the Crash Logging system.
     - Parameters:
     - message: The message
     - properties: A dictionary containing additional information about this message
     - level: The level of severity to report
    */
    func logMessage(_ message: String, properties: [String: Any]?, level: SeverityLevel)

    /**
     Writes an error to the Crash Logging system.
     - Parameters:
     - error: The error
     - userInfo: A dictionary containing additional information about this message
     - level: The level of severity to report
    */
    func logError(_ error: Error, userInfo: [String: Any]?, level: SeverityLevel)

    /**
     Writes an error to the Crash Logging system and waits until the message is sent.
     - Parameters:
     - error: The error
     - userInfo: A dictionary containing additional information about this message
     - level: The level of severity to report
    */
    func logErrorAndWait(_ error: Error, userInfo: [String: Any]?, level: SeverityLevel)
}
