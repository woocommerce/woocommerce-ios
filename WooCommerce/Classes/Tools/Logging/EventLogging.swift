import BuildSecrets
import Foundation
import AutomatticTracks
import AutomatticEncryptedLogs

struct WCEventLoggingDataSource: EventLoggingDataSource {
    var loggingEncryptionKey: String {
        return BuildSecrets.current.loggingEncryptionKey
    }

    var loggingAuthenticationToken: String {
        return BuildSecrets.current.oauth.secret
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

        // We should not access `ServiceLocator.crashLogging`(Owner of this) in the same runloop because there is a change that it has not yet been initialized
        // And we will create a run loop by calling it recursively.
        DispatchQueue.main.async {
            DDLogDebug("📜\t There are \(ServiceLocator.crashLogging.queuedLogFileCount) logs in the queue.")
        }
    }

    func didStartUploadingLog(_ log: LogFile) {
        DDLogDebug("📜 Started uploading encrypted log: \(log.uuid)")
    }

    func didFinishUploadingLog(_ log: LogFile) {
        DDLogDebug("📜 Finished uploading encrypted log: \(log.uuid)")

        // We should not access `ServiceLocator.crashLogging`(Owner of this) in the same runloop because there is a change that it has not yet been initialized
        // And we will create a run loop by calling it recursively.
        DispatchQueue.main.async {
            DDLogDebug("📜\t There are \(ServiceLocator.crashLogging.queuedLogFileCount) logs remaining in the queue.")
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
