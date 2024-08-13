import WatchConnectivity
import Combine
import Networking
import class WooFoundation.CurrencySettings

/// Type that syncs the necessary dependencies to the watch session.
///
final class WatchDependenciesSynchronizer: NSObject, WCSessionDelegate {

    /// Current WatchKit Session
    private let watchSession: WCSession

    /// Subscriptions store for combine publishers
    ///
    private var subscriptions = Set<AnyCancellable>()

    /// Update this value to sync a new storeID with the paired counterpart.
    ///
    @Published var storeID: Int64?

    /// Update this value to sync a new store name with the paired counterpart.
    ///
    @Published var storeName: String?

    /// Update this value to sync new credentials with the paired counterpart.
    ///
    @Published var credentials: Credentials?

    /// Update this value to sync the crash report opt in value with the paired counterpart.
    ///
    @Published var enablesCrashReports: Bool = true

    /// Update this value to sync the account with the paired counterpart.
    ///
    @Published var account: Account?

    /// Tracks if the current watch session is active or not
    ///
    @Published private var isSessionActive: Bool = false

    /// Toggle this value to force a credentials sync.
    ///
    @Published private var syncTrigger = false

    init(watchSession: WCSession = WCSession.default, storedDependencies: WatchDependencies?) {
        self.watchSession = watchSession
        super.init()

        self.storeID = storedDependencies?.storeID
        self.storeName = storedDependencies?.storeName
        self.credentials = storedDependencies?.credentials

        if let storedDependencies {
            self.enablesCrashReports = storedDependencies.enablesCrashReports
            self.account = storedDependencies.account
        }

        bindAndSyncDependencies()

        if WCSession.isSupported() {
            watchSession.delegate = self
            watchSession.activate()
        }
    }

    /// Gather all the necessary dependencies inputs and syncs them when the session is active.
    ///
    private func bindAndSyncDependencies() {

        // Convert all inputs into a dependencies type.
        // Additionally filter any duplicates and debounce signal by 0.5s
        // TODO: currencySettings should be treated as a new input but unfortunately there is no way to access it yet other than the ServiceLocator

        let requiredDependencies = Publishers.CombineLatest4($storeID, $storeName, $credentials, Just(ServiceLocator.currencySettings))
        let configurationDependencies = Publishers.CombineLatest($enablesCrashReports, $account)

        let watchDependencies = Publishers.CombineLatest(requiredDependencies, configurationDependencies)
            .map { (required, configuration) -> WatchDependencies? in

                let (storeID, storeName, credentials, currencySettings) = required
                let (enablesCrashReports, account) = configuration

                guard let storeID, let storeName, let credentials else {
                    return nil
                }

                return .init(storeID: storeID,
                             storeName: storeName,
                             currencySettings: currencySettings,
                             credentials: credentials,
                             enablesCrashReports: enablesCrashReports,
                             account: account)
            }
            .removeDuplicates()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)

        // Syncs the dependencies to the paired counterpart when the session becomes available.
        Publishers.CombineLatest3(watchDependencies, $isSessionActive, $syncTrigger)
            .sink { [watchSession] dependencies, isSessionActive, forceSync in
                guard isSessionActive else { return }
                do {

                    // If dependencies is nil, send an empty dictionary. This is most likely a logged out state
                    guard let dependencies else {
                        return try watchSession.updateApplicationContext([:])
                    }

                    let data = try JSONEncoder().encode(dependencies)
                    if var jsonObject = try JSONSerialization.jsonObject(with: data, options: .topLevelDictionaryAssumed) as? [String: Any] {

                        /// Adds a random key to the json object to force the framework to send it the application context again.
                        if forceSync {
                            jsonObject[Self.forceKey] = Date.now.timeIntervalSince1970
                        }

                        try watchSession.updateApplicationContext(jsonObject)
                    } else {
                        DDLogError("⛔️ Unable to encode watch dependencies for synchronization. Resulting object is not a dictionary")
                    }
                } catch {
                    DDLogError("⛔️ Error synchronizing credentials into watch session: \(error)")
                }
            }
            .store(in: &subscriptions)
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DDLogInfo("🔵 WatchSession activated \(activationState)")
        self.isSessionActive = activationState == .activated
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // No op
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Try to guarantee an active session
        self.isSessionActive = false
        watchSession.activate()
    }
}

// MARK: Tracks Delegate
extension WatchDependenciesSynchronizer {
    /// Tracks are being sent by the paired counterpart to be sent by the iOS App.
    /// This is in order to not duplicate tracks configuration which involve quite a lot of information to be transmitted to the watch.
    ///
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {

        // The user info could contain a track event. Send it if we found one.
        guard let rawEvent = userInfo[WooConstants.watchTracksKey] as? String,
              let analyticEvent = WooAnalyticsStat(rawValue: rawEvent) else {
            return DDLogError("⛔️ Unsupported watch tracks event: \(userInfo)")
        }
        ServiceLocator.analytics.track(analyticEvent)
    }
}

// MARK: Sync Delegate
extension WatchDependenciesSynchronizer {

    /// Key to force a force sync
    ///
    private static let forceKey = "force-sync"

    /// The `didReceiveMessage` only supports sync requests events for now.
    /// When one is identified we should try to re-sync credentials.
    ///
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard message[WooConstants.watchSyncKey] as? Bool == true else {
            return DDLogError("⛔️ Unsupported sync request message: \(message)")
        }

        syncTrigger.toggle()
    }
}
