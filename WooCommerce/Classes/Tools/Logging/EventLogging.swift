import Foundation
import AutomatticTracks

struct WCEventLoggingDataSource: EventLoggingDataSource {
    var loggingEncryptionKey: String {
        return ApiCredentials.loggingEncryptionKey
    }

    var loggingAuthenticationToken: String {
        return ApiCredentials.dotcomSecret
    }

    func logFilePath(forErrorLevel: EventLoggingErrorType, at date: Date) -> URL? {
        debugPrint("📜 Looking up log file path")
        guard let logFileInfo = ServiceLocator.fileLogger.logFileManager.sortedLogFileInfos.first else {
            debugPrint("📜 No log file path found – aborting")
            return nil
        }

        debugPrint("📜 Found log file path at \(logFileInfo.filePath)")
        return URL(fileURLWithPath: logFileInfo.filePath)
    }
}

struct WCEventLoggingDelegate: EventLoggingDelegate {

    var shouldUploadLogFiles: Bool {
        return
            !ProcessInfo.processInfo.isLowPowerModeEnabled
            && CrashLoggingSettings.didOptIn
    }

    func didQueueLogForUpload(_ log: LogFile) {
        DDLogDebug("📜 Added log to queue: \(log.uuid)")

        if let eventLogging = CrashLogging.eventLogging {
            DDLogDebug("📜\t There are \(eventLogging.queuedLogFiles.count) logs in the queue.")
        }
    }

    func didStartUploadingLog(_ log: LogFile) {
        DDLogDebug("📜 Started uploading encrypted log: \(log.uuid)")
    }

    func didFinishUploadingLog(_ log: LogFile) {
        DDLogDebug("📜 Finished uploading encrypted log: \(log.uuid)")
        if let eventLogging = CrashLogging.eventLogging {
            DDLogDebug("📜\t There are \(eventLogging.queuedLogFiles.count) logs remaining in the queue.")
        }
    }

    func uploadFailed(withError error: Error, forLog log: LogFile) {
        DDLogError("📜 Error uploading encrypted log: \(log.uuid)")
        DDLogError("📜\t\(error.localizedDescription)")

        let nserror = error as NSError
        DDLogError("📜\t Code: \(nserror.code)")
        if let details = nserror.localizedFailureReason {
            DDLogError("📜\t Details: \(details)")
        }
    }
}
