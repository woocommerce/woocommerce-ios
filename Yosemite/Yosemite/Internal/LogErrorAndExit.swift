import Foundation

/// Logs the error in CocoaLumberjack and stops app execution.
///
/// Prefer to use this instead of `fatalError()` since messages in fatal errors are not shown
/// in Sentry. Using this method, Sentry will still only show “Fatal error” in the Issue message
/// but the `message` can now be accessed through the Encrypted Logging Console.
///
internal func logErrorAndExit(_ message: String, file: StaticString = #file, line: UInt = #line) -> Never {
    DDLogError(message)
    fatalError(message, file: file, line: line)
}
