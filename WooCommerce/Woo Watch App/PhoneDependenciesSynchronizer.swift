import Foundation
import WatchConnectivity
import KeychainAccess

/// Type that receives and stores the necessary dependencies from the phone session.
///
final class PhoneDependenciesSynchronizer: NSObject, ObservableObject, WCSessionDelegate {

    @Published var message = "Not Logged In"

    /// Secure store.
    private let keychain: Keychain

    /// Nonsecure store.
    private let userDefaults: UserDefaults

    override init() {
        self.keychain = Keychain().accessibility(.afterFirstUnlock)
        self.userDefaults = UserDefaults.standard
        super.init()

        updateMessage()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    /// Get the latest application context when the session activates
    ///
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("current app context: \(session.receivedApplicationContext)")

        guard !session.receivedApplicationContext.isEmpty else {
            return
        }

        DispatchQueue.main.async {
            self.storeDependencies(appContext: session.receivedApplicationContext)
            self.updateMessage()
        }
    }

    /// Get new application context on real time.
    ///
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.storeDependencies(appContext: applicationContext)
            self.updateMessage()
        }
    }

    /// Update UI from stored dependencies
    ///
    private func updateMessage() {
        let dependencies = loadDependencies()
        if let storeID = dependencies.storeID, dependencies.credentials != nil {
            message = "Store ID: \(storeID)"
        } else {
            message = "Not Logged In"
        }
    }

    /// Load stored dependencies
    ///
    private func loadDependencies() -> WatchDependencies {
        guard let secret = keychain[WooConstants.authToken],
              let username: String = userDefaults[.defaultUsername],
              let type: String = userDefaults[.defaultCredentialsType],
              let siteAddress: String = userDefaults[.defaultSiteAddress],
              let storeID: Int64 = userDefaults[.defaultStoreID] else {
            return WatchDependencies(storeID: nil, credentials: nil)
        }

        let credentials = Credentials(rawType: type, username: username, secret: secret, siteAddress: siteAddress)
        return WatchDependencies(storeID: storeID, credentials: credentials)
    }

    /// Store dependencies from the app context
    ///
    private func storeDependencies(appContext: [String: Any]) {

        let dependencies = WatchDependencies(dictionary: appContext)

        userDefaults[.defaultStoreID] = dependencies.storeID
        userDefaults[.defaultUsername] = dependencies.credentials?.username
        userDefaults[.defaultCredentialsType] = dependencies.credentials?.rawType
        userDefaults[.defaultSiteAddress] = dependencies.credentials?.siteAddress
        keychain[WooConstants.authToken] = dependencies.credentials?.secret
    }
}
