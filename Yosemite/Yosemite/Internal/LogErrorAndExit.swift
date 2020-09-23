import Foundation

/// Logs the error in CocoaLumberjack and stops app execution.
///
/// Prefer to use this instead of `fatalError()` since messages in fatal errors are not visible
/// in Sentry.
///
internal func logErrorAndExit(_ message: String, file: StaticString = #file, line: UInt = #line) {
    DDLogError(message)
    fatalError(message, file: file, line: line)
}
