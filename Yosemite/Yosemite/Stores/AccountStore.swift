import Combine
import Foundation
import Networking
import Storage


// MARK: - AccountStore
//
public class AccountStore: Store {
    private let remote: AccountRemoteProtocol
    private var cancellables = Set<AnyCancellable>()

    /// Shared private StorageType for use during synchronizeSites and synchronizeSitePlan processes
    ///
    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = AccountRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, remote: AccountRemoteProtocol) {
        self.remote = remote
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
        case .loadAndSynchronizeSiteIfNeeded(let siteID, let isJetpackConnectionPackageSupported, let onCompletion):
            loadAndSynchronizeSiteIfNeeded(siteID: siteID, isJetpackConnectionPackageSupported: isJetpackConnectionPackageSupported, onCompletion: onCompletion)
        case .synchronizeAccount(let onCompletion):
            synchronizeAccount(onCompletion: onCompletion)
        case .synchronizeAccountSettings(let userID, let onCompletion):
            synchronizeAccountSettings(userID: userID, onCompletion: onCompletion)
        case .synchronizeSites(let selectedSiteID, let isJetpackConnectionPackageSupported, let onCompletion):
            synchronizeSites(selectedSiteID: selectedSiteID,
                             isJetpackConnectionPackageSupported: isJetpackConnectionPackageSupported,
                             onCompletion: onCompletion)
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
    func synchronizeAccount(onCompletion: @escaping (Result<Account, Error>) -> Void) {
        remote.loadAccount { [weak self] result in
            if case let .success(account) = result {
                self?.upsertStoredAccount(readOnlyAccount: account)
            }

            onCompletion(result)
        }
    }


    /// Synchronizes the WordPress.com account settings associated with the Network's Auth Token.
    /// User ID is passed along because the API doesn't include it in the response.
    ///
    func synchronizeAccountSettings(userID: Int64, onCompletion: @escaping (Result<AccountSettings, Error>) -> Void) {
        remote.loadAccountSettings(for: userID) { [weak self] result in
            if case let .success(accountSettings) = result {
                self?.upsertStoredAccountSettings(readOnlyAccountSettings: accountSettings)
            }

            onCompletion(result)
        }
    }

    /// Returns the site if it exists in storage already. Otherwise, it synchronizes the WordPress.com sites and returns the site if it exists.
    ///
    func loadAndSynchronizeSiteIfNeeded(siteID: Int64, isJetpackConnectionPackageSupported: Bool, onCompletion: @escaping (Result<Site, Error>) -> Void) {
        if let site = storageManager.viewStorage.loadSite(siteID: siteID)?.toReadOnly() {
            onCompletion(.success(site))
        } else {
            synchronizeSites(selectedSiteID: siteID, isJetpackConnectionPackageSupported: isJetpackConnectionPackageSupported) { [weak self] result in
                guard let self = self else { return }
                guard let site = self.storageManager.viewStorage.loadSite(siteID: siteID)?.toReadOnly() else {
                    return onCompletion(.failure(SynchronizeSiteError.unknownSite))
                }
                onCompletion(.success(site))
            }
        }
    }

    /// Synchronizes the WordPress.com sites associated with the Network's Auth Token.
    ///
    func synchronizeSites(selectedSiteID: Int64?, isJetpackConnectionPackageSupported: Bool, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        remote.loadSites()
            .flatMap { result -> AnyPublisher<Result<[Site], Error>, Never> in
                switch result {
                case .success(let sites):
                    return sites.publisher.flatMap { [weak self] site -> AnyPublisher<Site, Never> in
                        let sitePublisher = Just<Site>(site).eraseToAnyPublisher()
                        guard let self = self else {
                            return sitePublisher
                        }

                        // If a site is connected to Jetpack via Jetpack Connection Package, some information about the site is unavailable or inaccurate
                        // in `me/sites` endpoint made in `AccountRemote.loadSites`.
                        // As a workaround, we need to make 2 other API requests (ref p91TBi-6lK-p2):
                        // - Check if WooCommerce plugin is active via `wc/v3/settings` endpoint
                        // - Fetch site metadata like the site name, description, and URL via `wp/v2/settings` endpoint
                        if site.isJetpackCPConnected, isJetpackConnectionPackageSupported {
                            let wcAvailabilityPublisher = self.remote.checkIfWooCommerceIsActive(for: site.siteID)
                            let wpSiteSettingsPublisher = self.remote.fetchWordPressSiteSettings(for: site.siteID)
                            return Publishers.Zip3(sitePublisher, wcAvailabilityPublisher, wpSiteSettingsPublisher)
                                .map {
                                    (site, isWooCommerceActiveResult, wpSiteSettingsResult) -> Site in
                                    var site = site
                                    if case let .success(isWooCommerceActive) = isWooCommerceActiveResult {
                                        site = site.copy(isWooCommerceActive: isWooCommerceActive)
                                    }
                                    if case let .success(wpSiteSettings) = wpSiteSettingsResult {
                                        site = site.copy(name: wpSiteSettings.name, description: wpSiteSettings.description, url: wpSiteSettings.url)
                                    }
                                    return site
                                }.eraseToAnyPublisher()
                        } else {
                            return sitePublisher
                        }
                    }.collect().map { .success($0) }.eraseToAnyPublisher()
                case .failure:
                    return Just<Result<[Site], Error>>(result).eraseToAnyPublisher()
                }
            }
            .sink { [weak self] result in
                switch result {
                case .success(let sites):
                    self?.upsertStoredSitesInBackground(readOnlySites: sites, selectedSiteID: selectedSiteID) {
                        onCompletion(.success(()))
                    }
                case .failure(let error):
                    onCompletion(.failure(error))
                }
            }.store(in: &cancellables)
    }

    /// Loads the site plan for the default site.
    ///
    func synchronizeSitePlan(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        remote.loadSitePlan(for: siteID) { [weak self] result in
            switch result {
            case .success(let siteplan):
                self?.updateStoredSitePlanInBackground(plan: siteplan) {
                    onCompletion(.success(()))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Loads the Account associated with the specified userID (if any!).
    ///
    func loadAccount(userID: Int64, onCompletion: @escaping (Account?) -> Void) {
        let account = storageManager.viewStorage.loadAccount(userID: userID)?.toReadOnly()
        onCompletion(account)
    }

    /// Submits the tracks opt-in / opt-out setting to be synced globally. 
    ///
    func updateAccountSettings(userID: Int64, tracksOptOut: Bool, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        remote.updateAccountSettings(for: userID, tracksOptOut: tracksOptOut) { result in
            switch result {
            case .success:
                onCompletion(.success(()))
            case .failure(let error):
                onCompletion(.failure(error))
            }
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
    func upsertStoredSitesInBackground(readOnlySites: [Networking.Site], selectedSiteID: Int64? = nil, onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            // Deletes sites in storage that are not in `readOnlySites` and not the selected site.
            let storageSites = derivedStorage.loadAllSites()
            let readOnlySiteIDs = readOnlySites.map(\.siteID)
            storageSites.filter { readOnlySiteIDs.contains($0.siteID) == false && $0.siteID != selectedSiteID }
                .forEach { remotelyDeletedSite in
                    derivedStorage.deleteObject(remotelyDeletedSite)
                }

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

enum SynchronizeSiteError: Error, Equatable {
    case unknownSite
}
