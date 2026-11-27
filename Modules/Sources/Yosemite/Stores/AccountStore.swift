import Combine
import Foundation
import Networking
import Storage
import Synchronization

// MARK: - AccountStore
//
public class AccountStore: Store {
    private let remote: AccountRemoteProtocol
    private var cancellables = Set<AnyCancellable>()
    private let siteSynchronizationState = SiteSynchronizationState()

    override public convenience init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        let remote = AccountRemote(network: network)
        self.init(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
    }

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: AccountRemoteProtocol) {
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
        case .loadAndSynchronizeSite(let siteID, let forcedUpdate, let shouldSynchronize, let onCompletion):
            loadAndSynchronizeSite(siteID: siteID,
                                   forcedUpdate: forcedUpdate,
                                   shouldSynchronize: shouldSynchronize,
                                   onCompletion: onCompletion)
        case .synchronizeAccount(let onCompletion):
            synchronizeAccount(onCompletion: onCompletion)
        case .synchronizeAccountSettings(let userID, let onCompletion):
            synchronizeAccountSettings(userID: userID, onCompletion: onCompletion)
        case .synchronizeSites(let siteIDToPreserve, let onCompletion):
            synchronizeSites(preservingSiteID: siteIDToPreserve, onCompletion: onCompletion)
        case .synchronizeSitesAndReturnSelectedSiteInfo(let siteAddress, let onCompletion):
            synchronizeSitesAndReturnSelectedSiteInfo(for: siteAddress, onCompletion: onCompletion)
        case .synchronizeSitePlan(let siteID, let onCompletion):
            synchronizeSitePlan(siteID: siteID, onCompletion: onCompletion)
        case .updateAccountSettings(let userID, let tracksOptOut, let onCompletion):
            updateAccountSettings(userID: userID, tracksOptOut: tracksOptOut, onCompletion: onCompletion)
        case .updateCrashReportingOptOut(let optOut, let onCompletion):
            updateCrashReportingOptOut(optOut: optOut, onCompletion: onCompletion)
        case let .loadNotificationSettings(deviceID, onCompletion):
            loadNotificationSettings(deviceID: deviceID, onCompletion: onCompletion)
        case .updateNotificationSettings(let notificationSettings, let onCompletion):
            updateNotificationSettings(notificationSettings: notificationSettings, onCompletion: onCompletion)
        case .closeAccount(let onCompletion):
            closeAccount(onCompletion: onCompletion)
        }
    }

    /// Prevents in-flight site synchronizations from updating storage after their session ends.
    public func cancelSiteSynchronizations() {
        siteSynchronizationState.cancel()
        let pendingCancellables = cancellables
        cancellables.removeAll()
        pendingCancellables.forEach { $0.cancel() }
    }
}


// MARK: - Services!
//
private extension AccountStore {

    /// Synchronizes the WordPress.com account associated with the Network's Auth Token.
    ///
    func synchronizeAccount(onCompletion: @escaping @MainActor @Sendable (Result<Account, Error>) -> Void) {
        remote.loadAccount { [weak self] result in
            if case let .success(account) = result {
                self?.upsertStoredAccount(readOnlyAccount: account, onCompletion: {
                    onCompletion(result)
                })
            } else {
                MainActor.assumeIsolated { onCompletion(result) }
            }
        }
    }


    /// Synchronizes the WordPress.com account settings associated with the Network's Auth Token.
    /// User ID is passed along because the API doesn't include it in the response.
    ///
    func synchronizeAccountSettings(userID: Int64, onCompletion: @escaping @MainActor @Sendable (Result<AccountSettings, Error>) -> Void) {
        remote.loadAccountSettings(for: userID) { [weak self] result in
            if case let .success(accountSettings) = result {
                self?.upsertStoredAccountSettings(readOnlyAccountSettings: accountSettings, onCompletion: {
                    onCompletion(result)
                })
            } else {
                MainActor.assumeIsolated { onCompletion(result) }
            }
        }
    }

    /// Returns the site if it exists in storage already and if forced update is not required.
    /// Otherwise, it synchronizes the WordPress.com sites and returns the site if it exists.
    ///
    func loadAndSynchronizeSite(siteID: Int64,
                                forcedUpdate: Bool,
                                shouldSynchronize: Bool,
                                onCompletion: @escaping @Sendable (Result<SiteLoadResult, Error>) -> Void) {
        if let site = storageManager.viewStorage.loadSite(siteID: siteID)?.toReadOnly(), !forcedUpdate {
            onCompletion(.success((site: site, synchronizationResult: nil)))
        } else if shouldSynchronize == false {
            onCompletion(.failure(SynchronizeSiteError.unknownSite))
        } else {
            synchronizeSites { [weak siteSynchronizationState, storageManager] result in
                guard siteSynchronizationState?.isActive == true else {
                    return onCompletion(.failure(CancellationError()))
                }
                if case let .failure(error) = result, error is CancellationError {
                    return onCompletion(.failure(error))
                }
                guard case let .success(synchronizationResult) = result else {
                    if let site = storageManager.viewStorage.loadSite(siteID: siteID)?.toReadOnly() {
                        return onCompletion(.success((site: site, synchronizationResult: nil)))
                    }
                    return onCompletion(.failure(SynchronizeSiteError.unknownSite))
                }
                guard let site = storageManager.viewStorage.loadSite(siteID: siteID)?.toReadOnly() else {
                    return onCompletion(.failure(SynchronizeSiteError.unknownSite))
                }
                onCompletion(.success((site: site, synchronizationResult: synchronizationResult)))
            }
        }
    }

    func synchronizeSitesAndReturnSelectedSiteInfo(for siteAddress: String,
                                                    onCompletion: @escaping @Sendable (Result<SelectedSiteSynchronizationResult, Error>) -> Void) {
        guard canApplySiteSynchronization else {
            return onCompletion(.failure(CancellationError()))
        }
        let request = SiteSynchronizationRequest(completion: onCompletion)
        remote.loadSites()
            .handleEvents(receiveCancel: { [weak siteSynchronizationState] in
                request.cancel(sessionIsActive: siteSynchronizationState?.isActive == true)
            })
            .sink { [weak self] result in
                switch result {
                case .success(let sites):
                    guard let self, self.canApplySiteSynchronization else {
                        return request.complete(.failure(CancellationError()))
                    }
                    guard let selectedSite = sites.first(where: { $0.url == siteAddress }) else {
                        return request.complete(.failure(NetworkError.notFound()))
                    }
                    guard request.beginPersistence() else { return }
                    self.upsertStoredSitesInBackground(readOnlySites: sites) { [siteSynchronizationState = self.siteSynchronizationState] wasApplied in
                        guard wasApplied, siteSynchronizationState.isActive else {
                            return request.complete(.failure(CancellationError()))
                        }
                        let synchronizationResult = SiteSynchronizationResult(
                            containsJetpackConnectionPackageSites: sites.contains(where: { $0.isJetpackCPConnected }),
                            siteIDs: sites.map(\.siteID)
                        )
                        request.complete(.success((site: selectedSite, synchronizationResult: synchronizationResult)))
                    }
                case .failure(let error):
                    request.complete(.failure(error))
                }
            }
            .store(in: &cancellables)
    }

    /// Synchronizes the WordPress.com sites associated with the Network's Auth Token.
    ///
    func synchronizeSites(preservingSiteID: Int64? = nil, onCompletion: @escaping @Sendable (Result<SiteSynchronizationResult, Error>) -> Void) {
        guard canApplySiteSynchronization else {
            return onCompletion(.failure(CancellationError()))
        }
        let request = SiteSynchronizationRequest(completion: onCompletion)
        remote.loadSites()
            .flatMap { [weak self] result -> AnyPublisher<Result<[Site], Error>, Never> in
                switch result {
                case .success(let sites):
                    return sites.publisher.flatMap { [weak self] site -> AnyPublisher<Site, Never> in
                        let sitePublisher = Just<Site>(site).eraseToAnyPublisher()
                        guard let self else {
                            return sitePublisher
                        }

                        // If a site is connected to Jetpack via Jetpack Connection Package, some information about the site is unavailable or inaccurate
                        // in `me/sites` endpoint made in `AccountRemote.loadSites`.
                        // As a workaround, we need to make 2 other API requests (ref p91TBi-6lK-p2):
                        // - Check if WooCommerce plugin is active via `wc/v3/settings` endpoint
                        // - Fetch site metadata like the site name, description, and URL via `wp/v2/settings` endpoint
                        if site.isJetpackCPConnected {
                            let wcAvailabilityPublisher = self.remote.checkIfWooCommerceIsActive(for: site.siteID)
                            let wpSiteSettingsPublisher = self.remote.fetchWordPressSiteSettings(for: site.siteID)
                            return Publishers.Zip3(sitePublisher, wcAvailabilityPublisher, wpSiteSettingsPublisher)
                                .map {site, isWooCommerceActiveResult, wpSiteSettingsResult -> Site in
                                    var site = site
                                    guard case let .success(isWooCommerceActive) = isWooCommerceActiveResult,
                                          case let .success(wpSiteSettings) = wpSiteSettingsResult else {
                                              return site
                                          }
                                    site = site.copy(isWooCommerceActive: isWooCommerceActive)
                                    site = site.copy(name: wpSiteSettings.name,
                                                     description: wpSiteSettings.description,
                                                     url: wpSiteSettings.url.normalizedToHTTPS(),
                                                     wasURLNormalizedToHTTPS: .some(wpSiteSettings.url.requiresHTTPSNormalization))
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
            .handleEvents(receiveCancel: { [weak siteSynchronizationState] in
                request.cancel(sessionIsActive: siteSynchronizationState?.isActive == true)
            })
            .sink { [weak self] result in
                switch result {
                case .success(let sites):
                    guard let self, self.canApplySiteSynchronization else {
                        return request.complete(.failure(CancellationError()))
                    }
                    let containsJCPSites = sites.contains(where: { $0.isJetpackCPConnected })
                    sites.forEach { self.persistHTTPSConfigurationRequirement(from: $0) }
                    guard request.beginPersistence() else { return }
                    let siteSynchronizationState = self.siteSynchronizationState
                    self.upsertStoredSitesInBackground(readOnlySites: sites, preservingSiteID: preservingSiteID) { wasApplied in
                        guard wasApplied, siteSynchronizationState.isActive else {
                            return request.complete(.failure(CancellationError()))
                        }
                        request.complete(.success(.init(containsJetpackConnectionPackageSites: containsJCPSites,
                                                    siteIDs: sites.map(\.siteID))))
                    }
                case .failure(let error):
                    request.complete(.failure(error))
                }
            }.store(in: &cancellables)
    }

    func persistHTTPSConfigurationRequirement(from site: Site) {
        guard let required = site.wasURLNormalizedToHTTPS else {
            return
        }
        dispatcher.dispatch(AppSettingsAction.setHTTPSConfigurationUpdateRequired(siteID: site.siteID, required: required))
    }

    /// Loads the site plan for the default site.
    ///
    func synchronizeSitePlan(siteID: Int64, onCompletion: @escaping @MainActor @Sendable (Result<Void, Error>) -> Void) {
        remote.loadSitePlan(for: siteID) { [weak self] result in
            switch result {
            case .success(let siteplan):
                self?.updateStoredSitePlanInBackground(plan: siteplan) {
                    onCompletion(.success(()))
                }
            case .failure(let error):
                MainActor.assumeIsolated { onCompletion(.failure(error)) }
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

    /// Submits the crash reporting opt-in / opt-out setting to be synced globally.
    ///
    func updateCrashReportingOptOut(optOut: Bool, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        remote.updateCrashReportingOptOut(optOut: optOut, completion: onCompletion)
    }

    func loadNotificationSettings(deviceID: Int64, onCompletion: @escaping @Sendable (Result<NotificationSettings, Error>) -> Void) {
        Task { [remote] in
            do {
                let settings = try await remote.loadNotificationSettings(deviceID: deviceID)
                onCompletion(.success(settings))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    func updateNotificationSettings(notificationSettings: NotificationSettings, onCompletion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        Task { [remote] in
            do {
                try await remote.updateNotificationSettings(with: notificationSettings)
                onCompletion(.success(()))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    func closeAccount(onCompletion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        Task { [remote] in
            do {
                try await remote.closeAccount()
                onCompletion(.success(()))
            } catch {
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
    func upsertStoredAccount(readOnlyAccount: Networking.Account, onCompletion: @escaping @MainActor @Sendable () -> Void) {
        performAndSaveOnMain({ storage in
            let storageAccount = storage.loadAccount(userID: readOnlyAccount.userID) ?? storage.insertNewObject(ofType: Storage.Account.self)

            storageAccount.update(with: readOnlyAccount)
        }, completion: onCompletion)
    }

    /// Updates (OR Inserts) the specified ReadOnly AccountSettings Entity into the Storage Layer.
    ///
    func upsertStoredAccountSettings(readOnlyAccountSettings: Networking.AccountSettings, onCompletion: @escaping @MainActor @Sendable () -> Void) {
        performAndSaveOnMain({ storage in
            let storageAccount = storage.loadAccountSettings(userID: readOnlyAccountSettings.userID) ??
            storage.insertNewObject(ofType: Storage.AccountSettings.self)
            storageAccount.update(with: readOnlyAccountSettings)
        }, completion: onCompletion)
    }

    /// Updates the specified ReadOnly Site Plan attribute in the Site entity, in the Storage Layer.
    ///
    func updateStoredSitePlanInBackground(plan: SitePlan, onCompletion: @escaping @MainActor @Sendable () -> Void) {
        performAndSaveOnMain({ derivedStorage in
            let storageSite = derivedStorage.loadSite(siteID: plan.siteID)
            storageSite?.plan = plan.shortName
        }, completion: onCompletion)
    }

    /// Updates (OR Inserts) the specified ReadOnly Site Entities into the Storage Layer.
    ///
    func upsertStoredSitesInBackground(readOnlySites: [Networking.Site],
                                      preservingSiteID: Int64? = nil,
                                      onCompletion: @escaping @Sendable (Bool) -> Void) {
        storageManager.performAndSave({ [weak siteSynchronizationState] derivedStorage -> Bool in
            guard siteSynchronizationState?.isActive == true else {
                return false
            }

            // Jetpack setup can preserve its just-verified site while `/me/sites` catches up.
            let storageSites = derivedStorage.loadAllSites()
            let readOnlySiteIDs = readOnlySites.map(\.siteID)
            storageSites.filter { readOnlySiteIDs.contains($0.siteID) == false && $0.siteID != preservingSiteID }
                .forEach { remotelyDeletedSite in
                    derivedStorage.deleteObject(remotelyDeletedSite)
                }

            for readOnlySite in readOnlySites {
                let storageSite = derivedStorage.loadSite(siteID: readOnlySite.siteID) ?? derivedStorage.insertNewObject(ofType: Storage.Site.self)
                storageSite.update(with: readOnlySite)
            }

            return true
        }, completion: { result in
            onCompletion((try? result.get()) == true)
        }, on: .main)
    }
}

private extension AccountStore {
    var canApplySiteSynchronization: Bool {
        siteSynchronizationState.isActive
    }

    func performAndSaveOnMain(_ operation: @escaping @Sendable (StorageType) -> Void,
                              completion: @escaping @MainActor @Sendable () -> Void) {
        storageManager.performAndSave(operation, completion: {
            MainActor.assumeIsolated { completion() }
        }, on: .main)
    }
}

private final class SiteSynchronizationState: Sendable {
    private let active = Mutex(true)

    var isActive: Bool {
        active.withLock { $0 }
    }

    func cancel() {
        active.withLock { $0 = false }
    }
}

private final class SiteSynchronizationRequest<Output: Sendable>: Sendable {
    private typealias Completion = @Sendable (Result<Output, Error>) -> Void

    private struct State {
        var completion: Completion?
        var persistencePending = false
    }

    private let state: Mutex<State>

    init(completion: @escaping @Sendable (Result<Output, Error>) -> Void) {
        state = Mutex(State(completion: completion))
    }

    func beginPersistence() -> Bool {
        state.withLock {
            guard $0.completion != nil else { return false }
            $0.persistencePending = true
            return true
        }
    }

    func complete(_ result: Result<Output, Error>) {
        takeCompletion()?(result)
    }

    func cancel(sessionIsActive: Bool) {
        takeCompletion(allowPendingPersistence: !sessionIsActive)?(.failure(CancellationError()))
    }

    private func takeCompletion(allowPendingPersistence: Bool = true) -> Completion? {
        state.withLock {
            guard allowPendingPersistence || !$0.persistencePending else { return nil }
            let completion = $0.completion
            $0.completion = nil
            return completion
        }
    }
}

enum SynchronizeSiteError: Error, Equatable {
    case unknownSite
}
