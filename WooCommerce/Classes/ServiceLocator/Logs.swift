import Foundation
import CocoaLumberjack

/// Abstracts the Login engine.
///
protocol Logs {
    var logFileManager: DDLogFileManager { get }
    var rollingFrequency: TimeInterval { get set }
}

extension DDFileLogger: Logs { }
