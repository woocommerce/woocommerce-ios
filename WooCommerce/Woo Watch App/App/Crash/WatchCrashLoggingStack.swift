import WooFoundationWatchOS
import NetworkingWatchOS

/// Minimal version of `WCCrashLoggingStack` for the watch app.
///
struct WatchCrashLoggingStack: CrashLoggingStack {
    private let crashLogging: CrashLogging
    private let crashLoggingDataProvider = WatchCrashLoggingDataProvider()

    init(account: Account?) {
        crashLoggingDataProvider.currentUser = Self.tracksUserFrom(account)
        self.crashLogging = CrashLogging(dataProvider: crashLoggingDataProvider)
        self.crashLogging.setNeedsDataRefresh()

        do {
            _ = try crashLogging.start()
        } catch {
            DDLogError("⛔️ Unable to start WatchCrashLoggingStack: \(error)")
        }
    }

    func crash() {
        crashLogging.crash()
    }

    var queuedLogFileCount: Int {
        DDLogWarn("queuedLogFileCount not supported")
        return 0
    }

    func logError(_ error: Error) {
        DDLogWarn("logError not supported")
    }

    func logMessage(_ message: String, properties: [String: Any]?, level: SeverityLevel) {
        DDLogWarn("logMessage not supported")
    }

    func logError(_ error: Error, userInfo: [String: Any]?, level: SeverityLevel) {
        DDLogWarn("logError not supported")
    }

    func logFatalErrorAndExit(_ error: Error, userInfo: [String: Any]?) -> Never {
        DDLogWarn("logFatalErrorAndExit not supported")
        fatalError(error.localizedDescription)
    }

    func setNeedsDataRefresh() {
        crashLogging.setNeedsDataRefresh()
    }

    func updateUserData(enablesCrashReports: Bool, account: Account?) {
        crashLoggingDataProvider.currentUser = Self.tracksUserFrom(account)
        crashLoggingDataProvider.userHasOptedOut = !enablesCrashReports
        setNeedsDataRefresh()
    }

    static func tracksUserFrom(_ account: Account?) -> TracksUser? {
        guard let account = account else {
            return nil
        }
        return TracksUser(userID: "\(account.userID)", email: account.email, username: account.username)
    }
}

/// Minimal version of `WCCrashLoggingDataProvider` for the watch app.
///
class WatchCrashLoggingDataProvider: CrashLoggingDataProvider {

    var sentryDSN: String {
        ApiCredentials.sentryDSN
    }

    var userHasOptedOut: Bool = false

    var buildType: String {
#if DEBUG
        "localDeveloper"
#elseif ALPHA
        "alpha"
#else
        "appStore"
#endif
    }

    var currentUser: TracksUser?
}
