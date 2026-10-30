import CocoaLumberjackSwift
import Foundation

struct RecentApplicationLogEntry: Equatable {
    enum Level: String {
        case warning = "w"
        case error = "e"
    }

    let date: Date
    let level: Level
    let message: String
}

protocol RecentApplicationLogProviding {
    func entries(since: Date, limit: Int) -> [RecentApplicationLogEntry]
}

/// Keeps a small in-memory window of warnings and errors with their original log levels.
/// CocoaLumberjack's file formatter does not persist the level, so the regular application log cannot be filtered reliably after the fact.
/// `@unchecked Sendable` bridges CocoaLumberjack's missing concurrency contract: writes run on `loggerQueue`, and reads use that same queue.
/// The unchecked conformance can be removed when CocoaLumberjack models this queue isolation as `Sendable`.
final class RecentApplicationLogProvider: DDAbstractLogger, RecentApplicationLogProviding, @unchecked Sendable {
    private var storedEntries: [RecentApplicationLogEntry] = []

    override func log(message logMessage: DDLogMessage) {
        let level: RecentApplicationLogEntry.Level
        if logMessage.flag.contains(.error) {
            level = .error
        } else if logMessage.flag.contains(.warning) {
            level = .warning
        } else {
            return
        }

        storedEntries.append(.init(date: logMessage.timestamp, level: level, message: logMessage.message))
        if storedEntries.count > Constants.maximumStoredEntries {
            storedEntries.removeFirst(storedEntries.count - Constants.maximumStoredEntries)
        }
    }

    func entries(since: Date, limit: Int) -> [RecentApplicationLogEntry] {
        let read = {
            Array(self.storedEntries.lazy.filter { $0.date >= since }.suffix(max(0, limit)))
        }
        if isOnInternalLoggerQueue {
            return read()
        }
        return loggerQueue.sync(execute: read)
    }

    private enum Constants {
        /// More than the context needs, while remaining bounded during warning-heavy sessions.
        static let maximumStoredEntries = 200
    }
}
