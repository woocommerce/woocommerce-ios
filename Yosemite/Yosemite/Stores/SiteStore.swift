import Foundation
import Networking
import protocol Storage.StorageType
import protocol Storage.StorageManagerType
import class Storage.Site

/// Handles `SiteAction`
///
public final class SiteStore: Store {
    // Keeps a strong reference to remote to keep requests alive.
    private let remote: SiteRemoteProtocol

    /// Shared private StorageType for use when upserting sites into storage.
    ///
    private lazy var sharedDerivedStorage: StorageType = {
        storageManager.writerDerivedStorage
    }()

    public init(remote: SiteRemoteProtocol,
                dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                network: Network) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    public convenience init(dotcomClientID: String,
                            dotcomClientSecret: String,
                            dispatcher: Dispatcher,
                            storageManager: StorageManagerType,
                            network: Network) {
        let remote = SiteRemote(network: network, dotcomClientID: dotcomClientID, dotcomClientSecret: dotcomClientSecret)
        self.init(remote: remote,
                  dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network)
    }

    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: SiteAction.self)
    }

    /// Called whenever a given Action is dispatched.
    ///
    public override func onAction(_ action: Action) {
        guard let action = action as? SiteAction else {
            assertionFailure("SiteStore received an unsupported action: \(action)")
            return
        }
        switch action {
        case .createSite(let name, let flow, let completion):
            createSite(name: name, flow: flow, completion: completion)
        case let .launchSite(siteID, completion):
            launchSite(siteID: siteID, completion: completion)
        case let .enableFreeTrial(siteID, profilerData, completion):
            enableFreeTrial(siteID: siteID, profilerData: profilerData, completion: completion)
        case let.syncSite(siteID, completion):
            syncSite(siteID: siteID, completion: completion)
        }
    }
}

private extension SiteStore {
    func createSite(name: String,
                    flow: SiteCreationFlow,
                    completion: @escaping (Result<SiteCreationResult, SiteCreationError>) -> Void) {
        Task { @MainActor in
            do {
                let response = try await remote.createSite(name: name, flow: flow)

                guard response.success else {
                    return completion(.failure(SiteCreationError.unsuccessful))
                }
                guard let siteID = Int64(response.site.siteID) else {
                    return completion(.failure(SiteCreationError.invalidSiteID))
                }
                completion(.success(.init(siteID: siteID,
                                          name: response.site.name,
                                          url: response.site.url,
                                          siteSlug: response.site.siteSlug)))
            } catch {
                completion(.failure(SiteCreationError(remoteError: error)))
            }
        }
    }

    func launchSite(siteID: Int64, completion: @escaping (Result<Void, SiteLaunchError>) -> Void) {
        Task { @MainActor in
            do {
                try await remote.launchSite(siteID: siteID)
                completion(.success(()))
            } catch {
                completion(.failure(SiteLaunchError(remoteError: error)))
            }
        }
    }

    func enableFreeTrial(siteID: Int64, profilerData: SiteProfilerData?, completion: @escaping (Result<Void, Error>) -> Void) {
        Task { @MainActor in
            do {
                try await remote.enableFreeTrial(siteID: siteID, profilerData: profilerData)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func syncSite(siteID: Int64, completion: @escaping (Result<Site, Error>) -> Void) {
        Task { @MainActor in
            do {
                let site = try await remote.loadSite(siteID: siteID)
                await upsertStoredSiteInBackground(readOnlySite: site)
                guard let syncedSite = storageManager.viewStorage.loadSite(siteID: siteID)?.toReadOnly() else {
                    return await MainActor.run {
                        completion(.failure(SynchronizeSiteError.unknownSite))
                    }
                }
                await MainActor.run {
                    completion(.success(syncedSite))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
}

private extension SiteStore {
    func upsertStoredSiteInBackground(readOnlySite: Networking.Site) async {
        await withCheckedContinuation { continuation in
            let derivedStorage = sharedDerivedStorage
            derivedStorage.perform {
                let storageSite = derivedStorage.loadSite(siteID: readOnlySite.siteID) ?? derivedStorage.insertNewObject(ofType: Storage.Site.self)
                storageSite.update(with: readOnlySite)
            }

            storageManager.saveDerivedType(derivedStorage: derivedStorage) {
                DispatchQueue.main.async(execute: { continuation.resume() })
            }
        }
    }
}

/// Possible site creation errors.
public enum SiteCreationError: Error, Equatable {
    /// The domain name should be a `wordpress.com` subdomain and can only contain lowercase letters (a-z) and numbers.
    case invalidDomain
    /// The domain has been taken.
    case domainExists
    /// The returned site ID for the created site is invalid - for example, not a string that can be converted to `Int64`.
    case invalidSiteID
    /// When the site creation result is returned but its `success` boolean is `false`.
    case unsuccessful
    /// Unexpected error from WPCOM.
    case unexpected(error: DotcomError)
    /// Unknown error that is not a `DotcomError` nor `Networking.SiteCreationError`.
    case unknown(description: String)

    public init(remoteError: Error) {
        switch remoteError {
        case let remoteError as Networking.SiteCreationError:
            switch remoteError {
            case .invalidDomain:
                self = .invalidDomain
            }
        case let remoteError as DotcomError:
            switch remoteError {
            case let .unknown(code, _):
                switch code {
                case "blog_name_exists":
                    self = .domainExists
                case "blog_name_only_lowercase_letters_and_numbers":
                    self = .invalidDomain
                default:
                    self = .unexpected(error: remoteError)
                }
            default:
                self = .unexpected(error: remoteError)
            }
        default:
            self = .unknown(description: remoteError.localizedDescription)
        }
    }
}

public enum SiteLaunchError: Error, Equatable {
    case alreadyLaunched
    case unexpected(description: String)

    init(remoteError: Error) {
        guard let error = remoteError as? WordPressApiError,
              case let .unknown(code, _) = error,
              code == "already-launched" else {
            self = .unexpected(description: remoteError.localizedDescription)
            return
        }
        self = .alreadyLaunched
    }
}
