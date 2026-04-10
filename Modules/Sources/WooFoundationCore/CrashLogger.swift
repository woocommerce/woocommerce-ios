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
     Writes an error to the Crash Logging system, waits until the message is sent, and exits the app

     This method assumes that the app is in an unrecoverable state and will prioritize sending an error event over having complete metadata.
     For instance, it will not attempt to attach the current user to the error, since we might be calling these because Core Data initialization failed.

     - Parameters:
     - error: The error
     - userInfo: A dictionary containing additional information about this message
    */
    func logFatalErrorAndExit(_ error: Error, userInfo: [String: Any]?) -> Never
}
