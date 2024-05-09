import WatchConnectivity
import enum Yosemite.Credentials

/// Type that syncs the necessary dependencies to the watch session.
/// Dependencies:
/// - Store ID
/// - Credentials
///
final class WatchDependenciesSynchronizer: NSObject, WCSessionDelegate {

    /// Current WatchKit Session
    private let watchSession: WCSession

    /// Dependencies waiting to be synced.
    /// Used when we are waiting for the watch session to activate.
    private var queuedDependencies: WatchDependencies?

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
    func update(storeID: Int64?, credentials: Credentials?) {

        let dependencies = WatchDependencies(storeID: storeID, credentials: credentials)

        // Enqueue dependencies if the session is not yet activated.
        guard watchSession.activationState == .activated else {
            queuedDependencies = dependencies
            return
        }

        do {
            try watchSession.updateApplicationContext(dependencies.toDictionary())
        } catch {
            DDLogError("⛔️ Error synchronizing credentials into watch session: \(error)")
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DDLogInfo("🔵 WatchSession activated \(activationState)")

        if let queuedDependencies {
            update(storeID: queuedDependencies.storeID, credentials: queuedDependencies.credentials)
            self.queuedDependencies = nil
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // No op
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // No op
    }
}
