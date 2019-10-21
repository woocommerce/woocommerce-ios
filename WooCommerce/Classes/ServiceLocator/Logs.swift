import CocoaLumberjack
import Foundation

/// Abstracts the Login engine.
///
protocol Logs {
    var logFileManager: DDLogFileManager { get }
    var rollingFrequency: TimeInterval { get set }
}

extension DDFileLogger: Logs {}
