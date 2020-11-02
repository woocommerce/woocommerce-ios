import Combine
import KeychainAccess
import WordPressAuthenticator

/// Checks and listens for observations when the Apple ID credential is revoked when the user previously signed in with Apple.
///
@available(iOS 13.0, *)
final class AppleIDCredentialChecker {
    /// Keychain access for SIWA auth token
    private lazy var keychain = Keychain(service: WooConstants.keychainServiceName)

    private let authenticator: WordPressAuthenticator
    private let stores: StoresManager

    private var cancellable: ObservationToken?
    private var cancellables = Set<AnyCancellable>()

    init(authenticator: WordPressAuthenticator = WordPressAuthenticator.shared, stores: StoresManager = ServiceLocator.stores) {
        self.authenticator = authenticator
        self.stores = stores
        observeAppDidBecomeActiveForCheckingAppleIDCredentialState()
    }

    deinit {
        cancellable?.cancel()
        cancellables.forEach {
            $0.cancel()
        }
    }

    func observeLoggedInStateForAppleIDObservations() {
        cancellable = stores.isLoggedIn.subscribe { [weak self] isLoggedIn in
            if isLoggedIn {
                self?.startObservingAppleIDCredentialRevoked()
            } else {
                self?.removeAppleIDFromKeychain()
                self?.stopObservingAppleIDCredentialRevoked()
            }
        }
    }
}

@available(iOS 13.0, *)
private extension AppleIDCredentialChecker {
    /// Checks Apple ID credential state on app launch and app switching.
    func observeAppDidBecomeActiveForCheckingAppleIDCredentialState() {
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkAppleIDCredentialState()
        }.store(in: &cancellables)
    }

    func checkAppleIDCredentialState() {
        // If not logged in, remove the Apple User ID from the keychain, if it exists.
        guard isLoggedIn() else {
            removeAppleIDFromKeychain()
            return
        }

        // Get the Apple User ID from the keychain
        guard let appleUserID = keychain.wooAppleID else {
            DDLogInfo("checkAppleIDCredentialState: No Apple ID found.")
            return
        }

        // Get the Apple User ID state. If not authorized, log out the account.
        authenticator.getAppleIDCredentialState(for: appleUserID) { [weak self] (state, error) in
            DDLogDebug("checkAppleIDCredentialState: Apple ID state: \(state.rawValue)")

            switch state {
            case .revoked:
                DDLogInfo("checkAppleIDCredentialState: Revoked Apple ID. User signed out.")
                self?.logOutRevokedAppleAccount()
            default:
                // An error exists only for the notFound state.
                // notFound is a valid state when logging in with an Apple account for the first time.
                if let error = error {
                    DDLogDebug("checkAppleIDCredentialState: Apple ID state not found: \(error.localizedDescription)")
                }
                break
            }
        }
    }
}

@available(iOS 13.0, *)
private extension AppleIDCredentialChecker {
    func startObservingAppleIDCredentialRevoked() {
        authenticator.startObservingAppleIDCredentialRevoked { [weak self] in
            guard let self = self else {
                return
            }
            // The user could have SIWA'ed earlier then changed to authenticate with another method, and thus the app still receives notifications on
            // revoked Apple credentials. We only want to log out the app when the app is currently signed in with Apple (Apple ID saved in Keychain).
            if self.isLoggedIn() && self.keychain.wooAppleID != nil {
                DDLogInfo("Apple credentialRevokedNotification received. User signed out.")
                self.logOutRevokedAppleAccount()
            }
        }
    }

    func stopObservingAppleIDCredentialRevoked() {
        authenticator.stopObservingAppleIDCredentialRevoked()
    }

    func logOutRevokedAppleAccount() {
        removeAppleIDFromKeychain()
        DispatchQueue.main.async { [weak self] in
            self?.logout()
        }
    }

    func removeAppleIDFromKeychain() {
        keychain.wooAppleID = nil
    }
}

// MARK: - Authentication helpers
//
@available(iOS 13.0, *)
private extension AppleIDCredentialChecker {
    func isLoggedIn() -> Bool {
        stores.isAuthenticated
    }

    func logout() {
        stores.deauthenticate()
    }
}
