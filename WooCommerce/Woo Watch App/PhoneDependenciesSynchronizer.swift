import Foundation
import WatchConnectivity

final class PhoneDependenciesSynchronizer: NSObject, ObservableObject, WCSessionDelegate {

    @Published var message = "Nothing yet"

    override init() {
        super.init()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("current app context: \(session.applicationContext)")
        DispatchQueue.main.async {
            self.message = session.applicationContext.description
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("Application Context: \(applicationContext)")
        DispatchQueue.main.async {
            self.message = applicationContext.description
        }
    }

    func extractDependencies(appContext: [String: Any]) {
        let storeID: Int64? = {
            guard let storeDic = appContext["store"] as? [String: Int64] else {
                return nil
            }

            return storeDic["id"]
        }()

        let credentials: Credentials? = {

            guard let credentialsDic = appContext["credentials"] as? [String: String] else {
                return nil
            }

            guard let type = credentialsDic["type"],
                  let username = credentialsDic["username"],
                  let secret = credentialsDic["secret"],
                  let siteAddress = credentialsDic["address"] else {
                return nil
            }

            switch type {
            case "AuthenticationType.wpcom":
                return .wpcom(username: username, authToken: secret, siteAddress: siteAddress)
            case "AuthenticationType.wporg":
                return .wporg(username: username, password: secret, siteAddress: siteAddress)
            case "AuthenticationType.applicationPassword":
                return .applicationPassword(username: username, password: secret, siteAddress: siteAddress)
            default:
                return nil
            }
        }()
    }
}

