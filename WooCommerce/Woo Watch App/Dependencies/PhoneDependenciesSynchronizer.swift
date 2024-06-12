import Foundation
import WatchConnectivity
import KeychainAccess
import NetworkingWatchOS
import WooFoundationWatchOS

/// Type that receives and stores the necessary dependencies from the phone session.
///
final class PhoneDependenciesSynchronizer: NSObject, ObservableObject, WCSessionDelegate {

    @Published var dependencies: WatchDependencies?

    var tracksProvider: WatchTracksProvider?

    /// Secure store.
    private let keychain: Keychain

    /// Nonsecure store.
    private let userDefaults: UserDefaults

    override init() {
        self.keychain = Keychain().accessibility(.afterFirstUnlock)
        self.userDefaults = UserDefaults.standard
        super.init()

        reloadDependencies()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    /// Sends a message to the paired counterpart to attempt a credential sync.
    /// This should be received in `WatchDependenciesSynchronizer.didReceiveMessage` method.
    ///
    func requestCredentialSync() {
        WCSession.default.sendMessage([WooConstants.watchSyncKey: true], replyHandler: nil)
    }

    /// Get the latest application context when the session activates
    ///
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.storeDependencies(appContext: session.receivedApplicationContext)
            self.reloadDependencies()

            self.tracksProvider?.flushQueuedEvents()

            // If we could not find dependencies after the session is activated try a credential sync.
            // Give it 1 second so the watch can successfully reach the counterpart.
            if self.dependencies == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.requestCredentialSync()
                }
            }
        }
    }

    /// Get new application context on real time.
    ///
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.storeDependencies(appContext: applicationContext)
            self.reloadDependencies()
        }
    }

    /// Update UI from stored dependencies
    ///
    private func reloadDependencies() {
        self.dependencies = loadDependencies()
    }

    /// Load stored dependencies
    ///
    private func loadDependencies() -> WatchDependencies? {
        guard let secret = keychain[WooConstants.authToken],
              let username: String = userDefaults[.defaultUsername],
              let type: String = userDefaults[.defaultCredentialsType],
              let siteAddress: String = userDefaults[.defaultSiteAddress],
              let storeID: Int64 = userDefaults[.defaultStoreID],
              let storeName: String = userDefaults[.defaultStoreName],
              let credentials = Credentials(rawType: type, username: username, secret: secret, siteAddress: siteAddress) else {
            return nil
        }

        let currencySettings: CurrencySettings = {
            guard let currencySettingsData = userDefaults[.defaultStoreCurrencySettings] as? Data,
                  let currencySettings = try? JSONDecoder().decode(CurrencySettings.self, from: currencySettingsData) else {
                return CurrencySettings()
            }
            return currencySettings
        }()

        return WatchDependencies(storeID: storeID, storeName: storeName, currencySettings: currencySettings, credentials: credentials)
    }

    /// Store dependencies from the app context
    /// Receiving an empty dictionary will clear the store as it likely mean that the user has logged out of the app.
    ///
    private func storeDependencies(appContext: [String: Any]) {
        let dependencies = WatchDependencies(dictionary: appContext)

        // Only store the dependencies if we get new values to store.
        guard self.dependencies != dependencies else {
            return
        }

        userDefaults[.defaultStoreID] = dependencies?.storeID
        userDefaults[.defaultStoreName] = dependencies?.storeName
        userDefaults[.defaultUsername] = dependencies?.credentials.username
        userDefaults[.defaultStoreCurrencySettings] = try? JSONEncoder().encode(dependencies?.currencySettings)
        userDefaults[.defaultCredentialsType] = dependencies?.credentials.rawType
        userDefaults[.defaultSiteAddress] = dependencies?.credentials.siteAddress
        keychain[WooConstants.authToken] = dependencies?.credentials.secret

        tracksProvider?.sendTracksEvent(.watchStoreDataSynced)
    }
}
