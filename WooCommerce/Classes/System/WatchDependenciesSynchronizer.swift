import WatchConnectivity
import Combine
import enum Networking.Credentials
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

    /// Tracks if the current watch session is active or not
    ///
    @Published private var isSessionActive: Bool = false

    init(watchSession: WCSession = WCSession.default, storedDependencies: WatchDependencies?) {
        self.watchSession = watchSession
        super.init()

        self.storeID = storedDependencies?.storeID
        self.storeName = storedDependencies?.storeName
        self.credentials = storedDependencies?.credentials

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
        let watchDependencies = Publishers.CombineLatest4($storeID, $storeName, $credentials, Just(ServiceLocator.currencySettings))
            .map { storeID, storeName, credentials, currencySettings -> WatchDependencies? in
                guard let storeID, let storeName, let credentials else {
                    return nil
                }
                return .init(storeID: storeID, storeName: storeName, currencySettings: currencySettings, credentials: credentials)
            }
            .removeDuplicates()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)

        // Syncs the dependencies to the paired counterpart when the session becomes available.
        Publishers.CombineLatest(watchDependencies, $isSessionActive)
            .sink { [watchSession] dependencies, isSessionActive in
                guard isSessionActive else { return }
                do {
                    let dependenciesDic = dependencies?.toDictionary() ?? [:]
                    try watchSession.updateApplicationContext(dependenciesDic)
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
