import WatchConnectivity
import enum Yosemite.Credentials

final class WatchDependenciesSynchronizer: NSObject, WCSessionDelegate {

    struct Queue {
        let storeID: Int64?
        let credentials: Credentials?
    }

    let watchSession: WCSession

    private var queuedDependencies: Queue?

    init(watchSession: WCSession = WCSession.default) {
        self.watchSession = watchSession
        super.init()

        if WCSession.isSupported() {
            watchSession.delegate = self
            watchSession.activate()
        }
    }

    func update(storeID: Int64?, credentials: Credentials?) {

        guard watchSession.activationState == .activated else {
            queuedDependencies = Queue(storeID: storeID, credentials: credentials)
            return
        }

        do {
            let dictionary = createDependenciesDictionary(storeID: storeID, credentials: credentials)
            try watchSession.updateApplicationContext(dictionary)
        } catch {
            DDLogError("⛔️ Error synchronizing credentials into watch session: \(error)")
        }
    }

    func createDependenciesDictionary(storeID: Int64?, credentials: Credentials?) -> [String: Any] {
        guard let credentials, let storeID else {
            return ["credentials": [:], "store": [:]]
        }

        return [
            "credentials": [
                "type": credentials.rawType,
                "username": credentials.username,
                "secret": credentials.secret,
                "address": credentials.siteAddress
            ],
            "store": [
                "id": storeID
            ]
        ]
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // No op
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
