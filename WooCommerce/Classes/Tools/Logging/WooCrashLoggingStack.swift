import Foundation
import AutomatticTracks
import Experiments
import Yosemite
import Sentry
import WooFoundation

/// A wrapper around the logging stack – provides shared initialization and configuration for Tracks Crash and Event Logging
struct WooCrashLoggingStack: CrashLoggingStack {
    static let QueuedLogsDidChangeNotification = NSNotification.Name("WPCrashLoggingQueueDidChange")

    let crashLogging: AutomatticTracks.CrashLogging
    let eventLogging: EventLogging

    private let crashLoggingDataProvider: WCCrashLoggingDataProvider
    private let eventLoggingDataProvider = WCEventLoggingDataSource()
    private let eventLoggingDelegate = WCEventLoggingDelegate()

    // When registering for a notification, the opaque observer that is returned should be stored so iOS can remove it later at deinit time.
    private let willEnterForegroundObserver: NSObjectProtocol

    init(featureFlagService: FeatureFlagService) {
        let eventLogging = EventLogging(dataSource: eventLoggingDataProvider, delegate: eventLoggingDelegate)

        self.eventLogging = eventLogging
        self.crashLoggingDataProvider = WCCrashLoggingDataProvider(featureFlagService: featureFlagService)
        self.crashLogging = AutomatticTracks.CrashLogging(dataProvider: crashLoggingDataProvider, eventLogging: eventLogging)

        /// Upload any remaining files any time the app becomes active
        self.willEnterForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: nil,
            using: { _ in
                eventLogging.uploadNextLogFileIfNeeded()
                DDLogDebug("📜 Resumed encrypted log upload queue due to app entering foreground")
            }

        )

        do {
            _ = try crashLogging.start()
        } catch {
            DDLogError("⛔️ Unable to start WooCrashLoggingStack: \(error)")
        }
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
        crashLoggingDataProvider.appIsCrashing = true
        crashLogging.logErrorAndWait(error, userInfo: userInfo, level: .fatal)
        fatalError(error.localizedDescription)
    }

    func setNeedsDataRefresh() {
        crashLogging.setNeedsDataRefresh()
    }

    var queuedLogFileCount: Int {
        eventLogging.queuedLogFiles.count
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

    let featureFlagService: FeatureFlagService

    let enableAppHangTracking = false
    let enableCaptureFailedRequests = false

    /// Tracks if the component has been initialized.
    ///
    private var hasBeenInitialized = false

    init(featureFlagService: FeatureFlagService) {
        self.featureFlagService = featureFlagService

        NotificationCenter.default.addObserver(self, selector: #selector(updateCrashLoggingSystem(_:)), name: .defaultAccountWasUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCrashLoggingSystem(_:)), name: .logOutEventReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCrashLoggingSystem(_:)), name: .StoresManagerDidUpdateDefaultSite, object: nil)

        /// Marks the component as initialized in the next run loop.
        ///
        DispatchQueue.main.async {
            self.hasBeenInitialized = true
        }
    }

    var userHasOptedOut: Bool {
        return !CrashLoggingSettings.didOptIn
    }

    var currentUser: TracksUser? {
        guard !appIsCrashing else {
            return nil
        }

        /// Avoids to access `ServiceLocator.stores` if the component has not been initialized to avoid a deadlock.
        /// Here are two ways we have identified the deadlock can happen.
        ///
        /// It is safe to access `SessionManager.standard.defaultAccountID` and `SessionManager.standard.anonymousUserID`
        /// as they are backed up by `UserDefaults` and don't have internal dependencies.
        ///
        ///  -------------------------------------------------------------
        ///
        /// - `ServiceLocated.stores` is invoked when the app starts.
        /// - It calls `ServiceLocator.storageManager` when restoring the auth state for a user.
        /// - `StorageManager` has `WooCrashLoggingStack` as a dependency which initializes the `Sentry` SDK.
        /// - When the `Sentry` SDK detects that there are queued crashes to be sent it tries to send them immediately, before sending those crashes,
        ///   `Sentry` calls a `currentUser` delegate (this computed variable) to properly identity the crashes.
        /// - The delegate accesses `ServiceLocator.stores` which causes a deadlock.
        ///
        ///   -------------------------------------------------------------
        ///
        /// - `ServiceLocated.stores` is invoked when the app starts.
        /// - It calls `ServiceLocator.storageManager` when restoring the auth state for a user.
        /// - If `ServiceLocator.storageManager` fails to load or migrate its DB it will log a message using the `WooCrashLoggingStack`
        /// - `WooCrashLoggingStack`  initializes the `Sentry` SDK to log the message.
        /// - `Sentry` calls a `currentUser` delegate(this computed variable) to properly identity the messages.
        /// - The delegate accesses `ServiceLocator.stores` which causes a deadlock.
        ///
        guard hasBeenInitialized else {
            let bestGuessedID = SessionManager.standard.defaultAccountID.map { "\($0)" } ?? SessionManager.standard.anonymousUserID
            return TracksUser(userID: bestGuessedID, email: nil, username: nil)
        }

        guard let account = ServiceLocator.stores.sessionManager.defaultAccount else {
            let anonymousID = ServiceLocator.stores.sessionManager.anonymousUserID
            return TracksUser(userID: anonymousID, email: nil, username: nil)
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

    // MARK: – Performance Monitoring

    var performanceTracking: PerformanceTracking {
        guard featureFlagService.isFeatureFlagEnabled(.performanceMonitoring) else {
            return .disabled
        }

        return .enabled(
            .init(
                // FIXME: Is there a way to control this via feature flags?
                sampler: { 0.1 },
                trackCoreData: featureFlagService.isFeatureFlagEnabled(.performanceMonitoringCoreData),
                trackFileIO: featureFlagService.isFeatureFlagEnabled(.performanceMonitoringFileIO),
                trackNetwork: featureFlagService.isFeatureFlagEnabled(.performanceMonitoringNetworking),
                trackUserInteraction: featureFlagService.isFeatureFlagEnabled(.performanceMonitoringUserInteraction),
                trackViewControllers: featureFlagService.isFeatureFlagEnabled(.performanceMonitoringViewController)
            )
        )
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
