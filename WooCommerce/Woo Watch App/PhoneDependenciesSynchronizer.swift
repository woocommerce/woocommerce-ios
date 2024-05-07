import Foundation
import WatchConnectivity
import KeychainAccess

final class PhoneDependenciesSynchronizer: NSObject, ObservableObject, WCSessionDelegate {

    struct Dependencies {
        let storeID: Int64
        let credentials: Credentials
    }

    @Published var message = "Nothing yet"

    private let keychain: Keychain

    private let userDefaults: UserDefaults

    override init() {
        self.keychain = Keychain().accessibility(.afterFirstUnlock)
        self.userDefaults = UserDefaults.standard
        super.init()

        if let dependencies = self.loadDependencies() {
            self.message = "Store ID: \(dependencies.storeID)\nSiteAddress: \(dependencies.credentials.siteAddress)"
        }

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("current app context: \(session.applicationContext)")
        DispatchQueue.main.async {
            if !session.applicationContext.isEmpty {
                self.extractAndStoreDependencies(appContext: session.applicationContext)
                if let dependencies = self.loadDependencies() {
                    self.message = "Store ID: \(dependencies.storeID)\nSiteAddress: \(dependencies.credentials.siteAddress)"
                } else {
                    self.message = "Could not load dependencies"
                }
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("Application Context: \(applicationContext)")
        DispatchQueue.main.async {
            self.extractAndStoreDependencies(appContext: applicationContext)
            if let dependencies = self.loadDependencies() {
                self.message = "Store ID: \(dependencies.storeID)\nSiteAddress: \(dependencies.credentials.siteAddress)"
            } else {
                self.message = "Could not load dependencies"
            }
        }
    }

    func loadDependencies() -> Dependencies? {
        guard let secret = keychain["credentials.secret"],
              let username: String = userDefaults[.defaultUsername],
              let type: String = userDefaults[.defaultCredentialsType],
              let siteAddress: String = userDefaults[.defaultSiteAddress],
              let storeID: Int64 = userDefaults[.defaultStoreID] else {
            return nil
        }

        let credentials: Credentials? = {
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

        guard let credentials else {
            return nil
        }

        return Dependencies(storeID: storeID, credentials: credentials)
    }

    func extractAndStoreDependencies(appContext: [String: Any]) {
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

        keychain["credentials.secret"] = credentials?.secret
        userDefaults[.defaultUsername] = credentials?.username
        userDefaults[.defaultCredentialsType] = credentials?.rawType
        userDefaults[.defaultSiteAddress] = credentials?.siteAddress
        userDefaults[.defaultStoreID] = storeID
    }
}
