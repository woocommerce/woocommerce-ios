import Foundation
import Networking
import Storage
import SAMKeychain


// MARK: - AccountStore
//
public class AccountStore: Store {

    override public func registerSupportedActions() {
        // TODO: Implement Me!
    }

    override public func onAction(_ action: Action) {
        // TODO: Implement Me!
    }
}


// MARK: - Public Methods
//
extension AccountStore  {

    /// Synchronizes the WordPress.com account associated with a specified Authentication Token.
    ///
    public func synchronizeDotcomAccount(username: String, authToken: String, onCompletion: @escaping (Error?) -> Void) {
        let credentials = Credentials(authToken: authToken)
        let remote = AccountRemote(credentials: credentials, network: network)

        remote.loadAccountDetails { [weak self] (account, error) in
            guard let account = account else {
                onCompletion(error)
                return
            }

            self?.updateStoredAccount(remote: account)
            onCompletion(nil)
        }


        storeAuthToken(authToken, for: username)
        defaultUsername = username
    }

    ///
    ///
    public var defaultCredentials: Credentials? {
        guard let username = defaultUsername, let authToken = loadAuthToken(for: username) else {
            return nil
        }

        return Credentials(authToken: authToken)
    }

    ///
    ///
    public var defaultUsername: String? {
        get  {
            return UserDefaults.standard.string(forKey: Constants.defaultUsernameKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.defaultUsernameKey)
        }
    }
}


// MARK: - Keychain
//
extension AccountStore {

    /// Stores the specified Authentication Token, associated to a given Username.
    ///
    func storeAuthToken(_ token: String, for username: String) {
        SAMKeychain.setPassword(token, forService: Constants.keychainServiceName, account: username)
    }

    /// Returns the stored Authentication Token, if any.
    ///
    func loadAuthToken(for username: String) -> String? {
        return SAMKeychain.password(forService: Constants.keychainServiceName, account: username)
    }

    /// Removes the Authentication Token for the specified username.
    ///
    func removeAuthToken(for username: String) {
        SAMKeychain.deletePassword(forService: Constants.keychainServiceName, account: username)
    }
}


// MARK: - Private Methods
//
extension AccountStore {

    /// Updates the Storage's Account with the specified Networking (Remote) Account.
    ///
    func updateStoredAccount(remote: Networking.Account) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        let account = loadStoredAccount(userId: remote.userID) ?? storage.insertNewObject(ofType: Storage.Account.self)

        account.displayName = remote.displayName
        account.email = remote.email
        account.gravatarUrl = remote.gravatarUrl
        account.userID = Int64(remote.userID)
        account.username = remote.username

        storage.saveIfNeeded()
    }

    /// Retrieves the Stored Account.
    ///
    func loadStoredAccount(userId: Int) -> Storage.Account? {
        assert(Thread.isMainThread)

        let predicate = NSPredicate(format: "userID = %ld", userId)
        let storage = storageManager.viewStorage

        return storage.firstObject(ofType: Storage.Account.self, matching: predicate)
    }
}


// MARK: - Nested Types
//
private extension AccountStore {

    struct Constants {
        static let keychainServiceName = "com.automattic.woocommerce.account"
        static let defaultUsernameKey = "defaultUsernameKey"
    }
}

