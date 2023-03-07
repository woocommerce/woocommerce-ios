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

    init(featureFlagService: FeatureFlagService) {
        let eventLogging = EventLogging(dataSource: eventLoggingDataProvider, delegate: eventLoggingDelegate)

        self.eventLogging = eventLogging
        self.crashLoggingDataProvider = WCCrashLoggingDataProvider(featureFlagService: featureFlagService)
        self.crashLogging = AutomatticTracks.CrashLogging(dataProvider: crashLoggingDataProvider, eventLogging: eventLogging)

        /// Upload any remaining files any time the app becomes active
        let willEnterForeground = UIApplication.willEnterForegroundNotification
        NotificationCenter.default.addObserver(forName: willEnterForeground, object: nil, queue: nil, using: self.willEnterForeground)
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

    let featureFlagService: FeatureFlagService

    init(featureFlagService: FeatureFlagService) {
        self.featureFlagService = featureFlagService

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
