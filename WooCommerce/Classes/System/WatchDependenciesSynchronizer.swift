import WatchConnectivity
import enum Yosemite.Credentials

// TODO: change the name for Adapter? Bridge? Manager? Synchronizer?
final class WatchCredentialsSynchronizer: NSObject, WCSessionDelegate {

    let watchSession: WCSession

    private var queuedCredentials: Credentials?

    init(watchSession: WCSession = WCSession.default) {
        self.watchSession = watchSession
        super.init()

        if WCSession.isSupported() {
            watchSession.delegate = self
            watchSession.activate()
        }
    }

    // TODO: Handle null scenario
    func syncCredentials(_ credentials: Credentials?) {

        guard watchSession.activationState == .activated else {
            queuedCredentials = credentials
            return
        }

        do {
            let credDictionary = createCredentialDictionary(from: credentials)
            try watchSession.updateApplicationContext(credDictionary)
        } catch {
            DDLogError("⛔️ Error synchronizing credentials into watch session: \(error)")
        }
    }

    func createCredentialDictionary(from credential: Credentials?) -> [String: Any] {
        guard let credential else {
            return ["credential": [:]]
        }

        return [
            "credential": [
                "type": credential.rawType,
                "username": credential.username,
                "secret": credential.secret,
                "address": credential.siteAddress
            ]
        ]
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // No op
        DDLogInfo("🔵 WatchSession activated \(activationState)")

        if let credentials = queuedCredentials {
            syncCredentials(credentials)
            queuedCredentials = nil
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // No op
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // No op
    }
}
