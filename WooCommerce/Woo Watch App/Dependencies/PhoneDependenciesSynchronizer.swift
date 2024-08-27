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
        guard let dependenciesData = userDefaults[.watchDependencies] as? Data,
              let secret = keychain[WooConstants.authToken] else {
            return nil
        }

        let safeDependencies = try? JSONDecoder().decode(WatchDependencies.self, from: dependenciesData)
        return safeDependencies?.updatingSecret(secret: secret, applicationPassword: nil) // Inject stored secret
    }

    /// Store dependencies from the app context
    /// Receiving an empty dictionary will clear the store as it likely mean that the user has logged out of the app.
    ///
    private func storeDependencies(appContext: [String: Any]) {
        let dependencies: WatchDependencies? = {
            do {
                let data = try JSONSerialization.data(withJSONObject: appContext)
                return try JSONDecoder().decode(WatchDependencies.self, from: data)
            } catch {
                print ("Error decoding dependencies: \(error)")
                return nil
            }
        }()

        // Only store the dependencies if we get new values to store.
        guard self.dependencies != dependencies else {
            return
        }

        // Remove the secret from the dependencies object to not store the secret on a non-secure store.
        // The secret should be stored in the keychain
        let secret = dependencies?.credentials.secret
        let safeDependencies = dependencies?.removingSecret()

        userDefaults[.watchDependencies] = try? JSONEncoder().encode(safeDependencies)
        keychain[WooConstants.authToken] = secret

        // Make sure to store the provided application password in the keychain as it is needed for the networking request classes.
        updateApplicationPasswordStorage(dependencies: dependencies)

        tracksProvider?.sendTracksEvent(.watchStoreDataSynced)
    }

    /// Stores or removes the application password.
    ///
    private func updateApplicationPasswordStorage(dependencies: WatchDependencies?) {
        if let appPassword = dependencies?.applicationPassword {
            ApplicationPasswordStorage().saveApplicationPassword(appPassword)
        } else {
            ApplicationPasswordStorage().removeApplicationPassword()
        }
    }
}


private extension WatchDependencies {
    /// Removes the secret/auth token from the credential type and the application password.
    ///
    func removingSecret() -> WatchDependencies {
        updatingSecret(secret: "", applicationPassword: nil)
    }

    /// Replaces the secret/auth token with the provided value and the application password
    ///
    func updatingSecret(secret: String, applicationPassword: ApplicationPassword?) -> WatchDependencies {
        return WatchDependencies(storeID: storeID,
                                 storeName: storeName,
                                 currencySettings: currencySettings,
                                 credentials: credentials.replacingSecret(secret),
                                 applicationPassword: applicationPassword,
                                 enablesCrashReports: enablesCrashReports,
                                 account: account)
    }
}

private extension Credentials {
    /// Replaces the secret/auth token with the provided value.
    ///
    func replacingSecret(_ secret: String) -> Credentials {
        switch self {
        case let .applicationPassword(username, _, siteAddress):
            return .applicationPassword(username: username, password: secret, siteAddress: siteAddress)
        case let .wpcom(username, _, siteAddress):
            return .wpcom(username: username, authToken: secret, siteAddress: siteAddress)
        case let .wporg(username, _, siteAddress):
            return .wporg(username: username, password: secret, siteAddress: siteAddress)
        }
    }
}
