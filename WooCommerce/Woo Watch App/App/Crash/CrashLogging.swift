import Foundation
import Sentry
import WooFoundationWatchOS
import CocoaLumberjack

/// This class is copied from the Tacks Library and it is adapted for the Woo Watch App.
/// This should be removed/replaced when the Tracks Library properly supports watchOS.
///
/// A class that provides support for logging crashes. Not compatible with Objective-C.
public class CrashLogging {

    /// We haven't fully evicted global state from all of Tracks yet, so we keep a global reference around for now
    struct Internals {
        static var crashLogging: CrashLogging?
    }

    private let dataProvider: CrashLoggingDataProvider

    /// If you set this key to `true` in UserDefaults, crash logging will be
    /// sent even in DEBUG builds. If it is `false` or not present, then
    /// crash log events will only be sent in Release builds.
    public static let forceCrashLoggingKey = "force-crash-logging"

    public let flushTimeout: TimeInterval

    /// Initializes the crash logging system
    ///
    /// - Parameters:
    ///   - dataProvider: An object that provides any configuration to the crash logging system
    ///   - eventLogging: An associated `EventLogging` object that provides integration between the Crash Logging and Event Logging subsystems
    ///   - flushTimeout: The `TimeInterval` to wait for when flushing events and crahses queued to be sent to the remote
    public init(
        dataProvider: CrashLoggingDataProvider,
        flushTimeout: TimeInterval = 15
    ) {
        self.dataProvider = dataProvider
        self.flushTimeout = flushTimeout
    }

    /// Starts the CrashLogging subsystem by initializing Sentry.
    ///
    /// Should be called as early as possible in the application lifecycle
    public func start() throws -> CrashLogging {

        /// Validate the DSN ourselves before initializing, because the SentrySDK silently prints the error to the log instead of telling us if the DSN is valid
        _ = try SentryDsn(string: self.dataProvider.sentryDSN)

        SentrySDK.start { options in
            options.dsn = self.dataProvider.sentryDSN

            options.debug = true
            options.diagnosticLevel = .error

            options.environment = self.dataProvider.buildType
            options.enableAutoSessionTracking = self.dataProvider.shouldEnableAutomaticSessionTracking
            options.enableAppHangTracking = self.dataProvider.enableAppHangTracking
            options.enableCaptureFailedRequests = self.dataProvider.enableCaptureFailedRequests

            options.beforeSend = self.beforeSend

            /// Attach stack traces to non-fatal errors
            options.attachStacktrace = true

            // Events
            options.sampleRate = NSNumber(value: min(max(self.dataProvider.errorEventsSamplingRate, 0), 1))

            // Performance monitoring options
            options.enableAutoPerformanceTracing = self.dataProvider.enableAutoPerformanceTracking
            options.tracesSampler = { _ in
                // To keep our implementation as Sentry agnostic as possible, we don't pass the
                // input `SamplingContext` down the chain.
                NSNumber(value: self.dataProvider.tracesSampler())
            }
            options.enableNetworkTracking = self.dataProvider.enableNetworkTracking
            options.enableFileIOTracing = self.dataProvider.enableFileIOTracking
            options.enableCoreDataTracing = self.dataProvider.enableCoreDataTracking
            #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
                options.enableUserInteractionTracing = self.dataProvider.enableUserInteractionTracing
                options.enableUIViewControllerTracing = self.dataProvider.enableUIViewControllerTracking
            #endif
        }

        Internals.crashLogging = self

        return self
    }

    func beforeSend(event: Sentry.Event?) -> Sentry.Event? {

        #if DEBUG
        //let shouldSendEvent = UserDefaults.standard.bool(forKey: Self.forceCrashLoggingKey) && !dataProvider.userHasOptedOut
        let shouldSendEvent = !dataProvider.userHasOptedOut
        #else
        let shouldSendEvent = !dataProvider.userHasOptedOut
        #endif

        if shouldSendEvent == false {
            DDLogDebug("📜 Events will not be sent because user has opted-out.")
        }

        /// If we shouldn't send the event we have nothing else to do here
        guard let event = event, shouldSendEvent else {
            return nil
        }

        if event.tags == nil {
            event.tags = [String: String]()
        }

        event.tags?["locale"] = NSLocale.current.language.languageCode?.identifier

        // TODO: Apple watchOS does not exposes app state like iOS from UIApplication. This has to me implemented when required.
        /// Always provide a value in order to determine how often we're unable to retrieve application state
        event.tags?["app.state"] = "unknown"

        /// Read the current user from the Data Provider (though the Data Provider can decide not to provide it for functional or privacy reasons)
        event.user = dataProvider.currentUser?.sentryUser

        return event
    }

    /// Immediately crashes the application and generates a crash report.
    public func crash() {
        SentrySDK.crash()
    }

    enum Errors: LocalizedError {
        case unableToConstructAuthStringError
    }
}


// MARK: - User Tracking
extension CrashLogging {

    internal var currentUser: Sentry.User {

        let anonymousUser = TracksUser(userID: nil, email: nil, username: nil).sentryUser

        /// Don't continue if the data source doesn't yet have a user
        guard let user = dataProvider.currentUser else { return anonymousUser }
        let data = dataProvider.additionalUserData

        return user.sentryUser(withData: data)
    }

    /// Causes the Crash Logging System to refresh its knowledge about the current state of the system.
    ///
    /// This is required in situations like login / logout, when the system otherwise might not
    /// know a change has occured.
    ///
    /// Calling this method in these situations prevents
    public func setNeedsDataRefresh() {
        SentrySDK.setUser(currentUser)
    }
}

/// This class is copied from the Tacks Library and it is adapted for the Woo Watch App.
/// This should be removed/replaced when the Tracks Library properly supports watchOS.
///
public struct TracksUser {
    public let userID: String?
    public let email: String?
    public let username: String?

    public init(userID: String?, email: String?, username: String?) {
        self.userID = userID
        self.email = email
        self.username = username
    }

    public init(email: String) {
        self.userID = nil
        self.email = email
        self.username = nil
    }
}

/// This class is copied from the Tacks Library and it is adapted for the Woo Watch App.
/// This should be removed/replaced when the Tracks Library properly supports watchOS.
///
internal extension TracksUser {

    var sentryUser: Sentry.User {

        let user = Sentry.User()

        if let userID = self.userID {
            user.userId = userID
        }

        if let email = self.email {
            user.email = email
        }

        if let username = user.username {
            user.username = username
        }

        return user
    }

    func sentryUser(withData additionalUserData: [String: Any]) -> Sentry.User {
        let user = self.sentryUser
        user.data = additionalUserData
        return user
    }
}
