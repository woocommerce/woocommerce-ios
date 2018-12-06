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
        case .loadAccount(let userID, let onCompletion):
            loadAccount(userID: userID, onCompletion: onCompletion)
        case .loadSite(let siteID, let onCompletion):
            loadSite(siteID: siteID, onCompletion: onCompletion)
        case .synchronizeAccount(let onCompletion):
            synchronizeAccount(onCompletion: onCompletion)
        case .synchronizeSites(let onCompletion):
            synchronizeSites(onCompletion: onCompletion)
        case .synchronizeSitePlan(let siteID, let onCompletion):
            synchronizeSitePlan(siteID: siteID, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension AccountStore {

    /// Synchronizes the WordPress.com account associated with the Network's Auth Token.
    ///
    func synchronizeAccount(onCompletion: @escaping (Account?, Error?) -> Void) {
        let remote = AccountRemote(network: network)

        remote.loadAccount { [weak self] (account, error) in
            guard let account = account else {
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredAccount(readOnlyAccount: account)
            onCompletion(account, nil)
        }
    }

    /// Synchronizes the WordPress.com sites associated with the Network's Auth Token.
    ///
    func synchronizeSites(onCompletion: @escaping (Error?) -> Void) {
        let remote = AccountRemote(network: network)

        remote.loadSites { [weak self]  (sites, error) in
            guard let sites = sites else {
                onCompletion(error)
                return
            }

            self?.upsertStoredSites(readOnlySites: sites)
            onCompletion(nil)
        }
    }

    /// Loads the site plan for the default site.
    ///
    func synchronizeSitePlan(siteID: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = AccountRemote(network: network)
        remote.loadSitePlan(for: siteID) { [weak self]  (siteplan, error) in
            guard let siteplan = siteplan else {
                onCompletion(error)
                return
            }

            self?.updateStoredSite(plan: siteplan)
            onCompletion(nil)
        }
    }

    /// Loads the Account associated with the specified userID (if any!).
    ///
    func loadAccount(userID: Int, onCompletion: @escaping (Account?) -> Void) {
        let account = storageManager.viewStorage.loadAccount(userId: userID)?.toReadOnly()
        onCompletion(account)
    }

    /// Loads the Site associated with the specified siteID (if any!)
    ///
    func loadSite(siteID: Int, onCompletion: @escaping (Site?) -> Void) {
        let site = storageManager.viewStorage.loadSite(siteID: siteID)?.toReadOnly()
        onCompletion(site)
    }
}


// MARK: - Persistence
//
extension AccountStore {

    /// Updates (OR Inserts) the specified ReadOnly Account Entity into the Storage Layer.
    ///
    func upsertStoredAccount(readOnlyAccount: Networking.Account) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        let storageAccount = storage.loadAccount(userId: readOnlyAccount.userID) ?? storage.insertNewObject(ofType: Storage.Account.self)

        storageAccount.update(with: readOnlyAccount)
        storage.saveIfNeeded()
    }

    /// Updates (OR Inserts) the specified ReadOnly Site Entities into the Storage Layer.
    ///
    func upsertStoredSites(readOnlySites: [Networking.Site]) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage

        for readOnlySite in readOnlySites {
            let storageSite = storage.loadSite(siteID: readOnlySite.siteID) ?? storage.insertNewObject(ofType: Storage.Site.self)
            storageSite.update(with: readOnlySite)
        }

        storage.saveIfNeeded()
    }

    /// Updates the specified ReadOnly Site Plan attribute in the Site entity, in the Storage Layer.
    ///
    func updateStoredSite(plan: SitePlan) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage

        let storageSite = storage.loadSite(siteID: plan.siteID)
        storageSite?.plan = plan.shortName

        storage.saveIfNeeded()
    }
}
