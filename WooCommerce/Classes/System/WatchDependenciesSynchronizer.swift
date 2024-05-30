import WatchConnectivity
import enum Networking.Credentials
import class WooFoundation.CurrencySettings

/// Type that syncs the necessary dependencies to the watch session.
/// Dependencies:
/// - Store ID
/// - Credentials
///
final class WatchDependenciesSynchronizer: NSObject, WCSessionDelegate {

    private enum SyncState {
        case notQueued
        case queued(WatchDependencies?)
    }

    /// Current WatchKit Session
    private let watchSession: WCSession

    /// Dependencies waiting to be synced.
    /// Used when we are waiting for the watch session to activate.
    private var queuedDependencies: SyncState = .notQueued

    init(watchSession: WCSession = WCSession.default) {
        self.watchSession = watchSession
        super.init()

        if WCSession.isSupported() {
            watchSession.delegate = self
            watchSession.activate()
        }
    }

    /// Syncs credentials to the watch session.
    ///
    func update(storeID: Int64?, storeName: String?, currencySettings: CurrencySettings?, credentials: Credentials?) {

        let dependencies: WatchDependencies? = {
            guard let storeID, let storeName, let credentials, let currencySettings else {
                return nil
            }
            return .init(storeID: storeID, storeName: storeName, currencySettings: currencySettings, credentials: credentials)
        }()

        // Enqueue dependencies if the session is not yet activated.
        guard watchSession.activationState == .activated else {
            queuedDependencies = .queued(dependencies)
            return
        }

        do {
            let dependenciesDic = dependencies?.toDictionary() ?? [:]
            try watchSession.updateApplicationContext(dependenciesDic)
        } catch {
            DDLogError("⛔️ Error synchronizing credentials into watch session: \(error)")
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DDLogInfo("🔵 WatchSession activated \(activationState)")

        if case .queued(let watchDependencies) = queuedDependencies {
            update(storeID: watchDependencies?.storeID,
                   storeName: watchDependencies?.storeName,
                   currencySettings: watchDependencies?.currencySettings,
                   credentials: watchDependencies?.credentials)
            self.queuedDependencies = .notQueued
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // No op
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // No op
    }
}

extension WatchDependenciesSynchronizer {
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {

        // The user info could contain a track event. Send it if we found one.
        guard let rawEvent = userInfo[WooConstants.watchTracksKey] as? String,
              let analyticEvent = WooAnalyticsStat(rawValue: rawEvent) else {
            return DDLogError("⛔️ Unsupported watch tracks event: \(userInfo)")
        }
        ServiceLocator.analytics.track(analyticEvent)
    }
}
