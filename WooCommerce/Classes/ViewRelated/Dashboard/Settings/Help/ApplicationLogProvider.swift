import Foundation

protocol ApplicationLogProvider {
    func applicationLogs(cappedTo: Int?) -> String?
}

extension ApplicationLogProvider {
    func applicationLogs() -> String? {
        return applicationLogs(cappedTo: nil)
    }
}

final class DefaultApplicationLogProvider: ApplicationLogProvider {
    private let fileLogger: Logs

    init(fileLogger: Logs = ServiceLocator.fileLogger) {
        self.fileLogger = fileLogger
    }

    func applicationLogs(cappedTo: Int?) -> String? {
        guard let logFileInformation = fileLogger.logFileManager.sortedLogFileInfos.first,
              let logData = try? Data(contentsOf: URL(fileURLWithPath: logFileInformation.filePath)),
              let logText = String(data: logData, encoding: .utf8) else {
            return ""
        }

        // Truncates the log text so it fits in the ticket field.
        if let cappedTo, logText.count > cappedTo {
            return String(logText.suffix(cappedTo))
        }

        return logText
    }
}
