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
        case .synchronizeAccount(let onCompletion):
            synchronizeAccount(onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
extension AccountStore  {

    /// Synchronizes the WordPress.com account associated with the Network's Auth Token.
    ///
    func synchronizeAccount(onCompletion: @escaping (Account?, Error?) -> Void) {
        let remote = AccountRemote(network: network)

        remote.loadAccountDetails { [weak self] (account, error) in
            guard let account = account else {
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredAccount(remote: account)
            onCompletion(account, nil)
        }
    }
}


// MARK: - Persistance
//
extension AccountStore {

    /// Updates (OR Inserts) the Storage's Account with the specified (Networking) Account entity.
    ///
    func upsertStoredAccount(remote: Networking.Account) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        let account = loadStoredAccount(userId: remote.userID) ?? storage.insertNewObject(ofType: Storage.Account.self)

        account.update(with: remote)
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
