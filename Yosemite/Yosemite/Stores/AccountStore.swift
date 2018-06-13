import Foundation
import Networking
import Storage



// MARK: - AccountStore
//
public class AccountStore: Store {

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: AccountAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? AccountAction else {
            assertionFailure("AccountStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeAccountDetails(let onCompletion):
            synchronizeAccountDetails(onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
extension AccountStore  {

    /// Synchronizes the WordPress.com account associated with a specified Authentication Token.
    ///
    func synchronizeAccountDetails(onCompletion: @escaping (Error?) -> Void) {
        let remote = AccountRemote(network: network)

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


// MARK: - Persistance
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
