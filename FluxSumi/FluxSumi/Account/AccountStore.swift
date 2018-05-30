import Foundation
import Networking
import Storage


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
    public func synchronizeDotcomAccount(authToken: String, onCompletion: @escaping (Error?) -> Void) {
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

