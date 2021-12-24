import Foundation
import AutomatticTracks
import Experiments
import Storage
import Yosemite

/// A wrapper around the logging stack – provides shared initialization and configuration for Tracks Crash and Event Logging
struct WooCrashLoggingStack: CrashLoggingStack {
    static let QueuedLogsDidChangeNotification = NSNotification.Name("WPCrashLoggingQueueDidChange")

    let crashLogging: AutomatticTracks.CrashLogging
    let eventLogging: EventLogging

    private let crashLoggingDataProvider = WCCrashLoggingDataProvider()
    private let eventLoggingDataProvider = WCEventLoggingDataSource()
    private let eventLoggingDelegate = WCEventLoggingDelegate()

    init() {
        let eventLogging = EventLogging(dataSource: eventLoggingDataProvider, delegate: eventLoggingDelegate)

        self.eventLogging = eventLogging
        self.crashLogging = AutomatticTracks.CrashLogging(dataProvider: crashLoggingDataProvider, eventLogging: eventLogging)

        /// Upload any remaining files any time the app becomes active
        let willEnterForeground = UIApplication.willEnterForegroundNotification
        NotificationCenter.default.addObserver(forName: willEnterForeground, object: nil, queue: nil, using: self.willEnterForeground)
        _ = try? crashLogging.start()
    }

    func crash() {
        crashLogging.crash()
    }

    func logMessage(_ message: String, properties: [String: Any]?, level: SeverityLevel) {
        crashLogging.logMessage(message, properties: properties, level: sentrySeverity(with: level))
    }

    func logError(_ error: Error) {
        crashLogging.logError(error)
    }

    func logError(_ error: Error, userInfo: [String: Any]? = nil, level: SeverityLevel = .error) {
        crashLogging.logError(error, userInfo: userInfo, level: sentrySeverity(with: level))
    }

    func logFatalErrorAndExit(_ error: Error, userInfo: [String: Any]? = nil) -> Never {
        do {
            crashLoggingDataProvider.appIsCrashing = true
            try crashLogging.logErrorAndWait(error, userInfo: userInfo, level: .fatal)
        } catch {
            DDLogError("⛔️ Unable to send startup error message to Sentry: \(error)")
        }
        fatalError(error.localizedDescription)
    }

    func setNeedsDataRefresh() {
        crashLogging.setNeedsDataRefresh()
    }

    var queuedLogFileCount: Int {
        eventLogging.queuedLogFiles.count
    }

    private func willEnterForeground(note: Foundation.Notification) {
        self.eventLogging.uploadNextLogFileIfNeeded()
        DDLogDebug("📜 Resumed encrypted log upload queue due to app entering foreground")
    }

    private func sentrySeverity(with storageSeverity: SeverityLevel) -> SentryLevel {
        switch storageSeverity {
        case .fatal:
            return .fatal
        case .error:
            return .error
        case .warning:
            return .warning
        case .info:
            return .info
        case .debug:
            return .debug
        }
    }
}

class WCCrashLoggingDataProvider: CrashLoggingDataProvider {
    /// Indicates that app is in an inconsistent state and we don't want to start asking it for metadata
    fileprivate var appIsCrashing = false

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateCrashLoggingSystem(_:)), name: .defaultAccountWasUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCrashLoggingSystem(_:)), name: .logOutEventReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCrashLoggingSystem(_:)), name: .StoresManagerDidUpdateDefaultSite, object: nil)
    }

    var userHasOptedOut: Bool {
        return !CrashLoggingSettings.didOptIn
    }

    var currentUser: TracksUser? {
        guard !appIsCrashing else {
            return nil
        }

        guard let account = ServiceLocator.stores.sessionManager.defaultAccount else {
            return nil
        }

        return TracksUser(userID: "\(account.userID)", email: account.email, username: account.username)
    }

    var sentryDSN: String {
        return ApiCredentials.sentryDSN
    }

    var buildType: String {
        return BuildConfiguration.current.rawValue
    }

    var shouldEnableAutomaticSessionTracking: Bool {
        return CrashLoggingSettings.didOptIn
    }

    @objc func updateCrashLoggingSystem(_ notification: Notification) {
        /// Bumping this call to a later run loop is a little bit hack-y, but because the `StoresManager` fires the events
        /// we're interested as part of its initialization, we need to wait for that initalization to be complete before
        /// taking action – otherwise the application will deadlock.
        DispatchQueue.main.async {
            ServiceLocator.crashLogging.setNeedsDataRefresh()
        }
    }
}

struct CrashLoggingSettings {
    static var didOptIn: Bool {
        get {
            // By default, opt the user into crash reporting
            return UserDefaults.standard.object(forKey: .userOptedInCrashLogging) ?? true
        }
        set {
            if newValue {
                DDLogInfo("🔵 Crash Logging reporting restored.")
            }
            else {
                DDLogInfo("🔴 Crash Logging opt-out complete.")
            }

            UserDefaults.standard.set(newValue, forKey: .userOptedInCrashLogging)
        }
    }
}
