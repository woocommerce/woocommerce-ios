import Foundation
import Networking
import Storage


// MARK: - AccountStore
//
public class AccountStore: Store {
    private let remote: AccountRemote

    /// Shared private StorageType for use during synchronizeSites and synchronizeSitePlan processes
    ///
    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = AccountRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

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
        case .synchronizeAccountSettings(let userID, let onCompletion):
            synchronizeAccountSettings(userID: userID, onCompletion: onCompletion)
        case .synchronizeSites(let onCompletion):
            synchronizeSites(onCompletion: onCompletion)
        case .synchronizeSitePlan(let siteID, let onCompletion):
            synchronizeSitePlan(siteID: siteID, onCompletion: onCompletion)
        case .updateAccountSettings(let userID, let tracksOptOut, let onCompletion):
            updateAccountSettings(userID: userID, tracksOptOut: tracksOptOut, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension AccountStore {

    /// Synchronizes the WordPress.com account associated with the Network's Auth Token.
    ///
    func synchronizeAccount(onCompletion: @escaping (Account?, Error?) -> Void) {
        remote.loadAccount { [weak self] (account, error) in
            guard let account = account else {
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredAccount(readOnlyAccount: account)
            onCompletion(account, nil)
        }
    }


    /// Synchronizes the WordPress.com account settings associated with the Network's Auth Token.
    /// User ID is passed along because the API doesn't include it in the response.
    ///
    func synchronizeAccountSettings(userID: Int64, onCompletion: @escaping (AccountSettings?, Error?) -> Void) {
        remote.loadAccountSettings(for: userID) { [weak self] (accountSettings, error) in
            guard let accountSettings = accountSettings else {
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredAccountSettings(readOnlyAccountSettings: accountSettings)
            onCompletion(accountSettings, nil)
        }
    }

    /// Synchronizes the WordPress.com sites associated with the Network's Auth Token.
    ///
    func synchronizeSites(onCompletion: @escaping (Error?) -> Void) {
        remote.loadSites { [weak self]  (sites, error) in
            guard let sites = sites else {
                onCompletion(error)
                return
            }

            self?.upsertStoredSitesInBackground(readOnlySites: sites) {
                onCompletion(nil)
            }
        }
    }

    /// Loads the site plan for the default site.
    ///
    func synchronizeSitePlan(siteID: Int64, onCompletion: @escaping (Error?) -> Void) {
        remote.loadSitePlan(for: siteID) { [weak self]  (siteplan, error) in
            guard let siteplan = siteplan else {
                onCompletion(error)
                return
            }

            self?.updateStoredSitePlanInBackground(plan: siteplan) {
                onCompletion(nil)
            }
        }
    }

    /// Loads the Account associated with the specified userID (if any!).
    ///
    func loadAccount(userID: Int64, onCompletion: @escaping (Account?) -> Void) {
        let account = storageManager.viewStorage.loadAccount(userID: userID)?.toReadOnly()
        onCompletion(account)
    }

    /// Loads the Site associated with the specified siteID (if any!)
    ///
    func loadSite(siteID: Int64, onCompletion: @escaping (Site?) -> Void) {
        let site = storageManager.viewStorage.loadSite(siteID: siteID)?.toReadOnly()
        onCompletion(site)
    }

    /// Submits the tracks opt-in / opt-out setting to be synced globally. 
    ///
    func updateAccountSettings(userID: Int64, tracksOptOut: Bool, onCompletion: @escaping (Error?) -> Void) {
        remote.updateAccountSettings(for: userID, tracksOptOut: tracksOptOut) { accountSettings, error in
            guard let _ = accountSettings else {
                onCompletion(error)
                return
            }

            onCompletion(nil)
        }
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
        let storageAccount = storage.loadAccount(userID: readOnlyAccount.userID) ?? storage.insertNewObject(ofType: Storage.Account.self)

        storageAccount.update(with: readOnlyAccount)
        storage.saveIfNeeded()
    }

    /// Updates (OR Inserts) the specified ReadOnly AccountSettings Entity into the Storage Layer.
    ///
    func upsertStoredAccountSettings(readOnlyAccountSettings: Networking.AccountSettings) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        let storageAccount = storage.loadAccountSettings(userID: readOnlyAccountSettings.userID) ??
            storage.insertNewObject(ofType: Storage.AccountSettings.self)

        storageAccount.update(with: readOnlyAccountSettings)
        storage.saveIfNeeded()
    }

    /// Updates the specified ReadOnly Site Plan attribute in the Site entity, in the Storage Layer.
    ///
    func updateStoredSitePlanInBackground(plan: SitePlan, onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            let storageSite = derivedStorage.loadSite(siteID: plan.siteID)
            storageSite?.plan = plan.shortName
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly Site Entities into the Storage Layer.
    ///
    func upsertStoredSitesInBackground(readOnlySites: [Networking.Site], onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            for readOnlySite in readOnlySites {
                let storageSite = derivedStorage.loadSite(siteID: readOnlySite.siteID) ?? derivedStorage.insertNewObject(ofType: Storage.Site.self)
                storageSite.update(with: readOnlySite)
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}
