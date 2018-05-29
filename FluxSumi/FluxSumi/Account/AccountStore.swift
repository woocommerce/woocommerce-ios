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
    public func synchronizeDotcomAccount(with authToken: String, onCompletion: @escaping (Error?) -> Void) {
        let credentials = Credentials(authToken: authToken)
        let remote = AccountRemote(credentials: credentials)

        remote.loadAccountDetails { [weak self] (account, error) in
            guard let account = account else {
                onCompletion(error)
                return
            }

            self?.updateStoredAccount(with: account)
            onCompletion(nil)
        }
    }
}


// MARK: - Private Methods
//
private extension AccountStore {

    /// Updates the Storage's Account with the specified Networking (Remote) Account.
    ///
    func updateStoredAccount(with remote: Networking.Account) {
        assert(Thread.isMainThread)

        let predicate = NSPredicate(format: "userID = %ld", remote.userID)
        let storage = storageManager.viewStorage
        let account = storage.firstObject(ofType: Storage.Account.self, matching: predicate) ?? storage.insertNewObject(ofType: Storage.Account.self)

        account.displayName = remote.displayName
        account.email = remote.email
        account.gravatarUrl = remote.gravatarUrl
        account.userID = Int64(remote.userID)
        account.username = remote.username

        storage.saveIfNeeded()
    }
}
