import Foundation
import Networking
import Storage


// MARK: - BlazeStore
//
public final class BlazeStore: Store {
    private let remote: BlazeRemoteProtocol

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: BlazeRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Initializes a new BlazeStore.
    /// - Parameters:
    ///   - dispatcher: The dispatcher used to subscribe to `BlazeAction`.
    ///   - storageManager: The storage layer used to store and retrieve persisted Blaze campaigns.
    ///   - network: The network layer used to fetch Blaze campaigns
    ///
    public override convenience init(dispatcher: Dispatcher,
                                     storageManager: StorageManagerType,
                                     network: Network) {
        self.init(dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network,
                  remote: BlazeRemote(network: network))
    }

    // MARK: - Actions

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: BlazeAction.self)
    }

    /// Receives and executes Actions.
    /// - Parameters:
    ///   - action: An action to handle. Must be a `BlazeAction`
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? BlazeAction else {
            assertionFailure("BlazeStore received an unsupported action")
            return
        }

        switch action {
        case let .synchronizeCampaigns(siteID, pageNumber, onCompletion):
            synchronizeCampaigns(siteID: siteID,
                                 pageNumber: pageNumber,
                                 onCompletion: onCompletion)
        case let .synchronizeTargetDevices(siteID, locale, onCompletion):
            synchronizeTargetDevices(siteID: siteID, locale: locale, onCompletion: onCompletion)
        }
    }
}

// MARK: - Synchronized campaigns
//
private extension BlazeStore {
    func synchronizeCampaigns(siteID: Int64, pageNumber: Int, onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        Task { @MainActor in
            do {
                let results = try await remote.loadCampaigns(for: siteID, pageNumber: pageNumber)
                let shouldClearData = pageNumber == Default.firstPageNumber
                let hasNextPage = !results.isEmpty // optimistic check because we don't have page size for this API.
                upsertStoredCampaignsInBackground(readOnlyCampaigns: results, siteID: siteID, shouldClearExistingCampaigns: shouldClearData) {
                    onCompletion(.success(hasNextPage))
                }
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Updates or Inserts specified BlazeCampaign Entities in a background thread
    /// `onCompletion` will be called on the main thread.
    ///
    func upsertStoredCampaignsInBackground(readOnlyCampaigns: [Networking.BlazeCampaign],
                                           siteID: Int64,
                                           shouldClearExistingCampaigns: Bool = false,
                                           onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            guard let self = self else { return }
            if shouldClearExistingCampaigns {
                derivedStorage.deleteBlazeCampaigns(siteID: siteID)
            }
            self.upsertStoredCampaigns(readOnlyCampaigns: readOnlyCampaigns,
                                       in: derivedStorage,
                                       siteID: siteID)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates or Inserts the specified Blaze campaign entities
    ///
    func upsertStoredCampaigns(readOnlyCampaigns: [Networking.BlazeCampaign],
                               in storage: StorageType,
                               siteID: Int64) {
        for campaign in readOnlyCampaigns {
            let storageCampaign: Storage.BlazeCampaign = {
                if let storedCampaign = storage.loadBlazeCampaign(siteID: siteID, campaignID: campaign.campaignID) {
                    return storedCampaign
                }
                return storage.insertNewObject(ofType: Storage.BlazeCampaign.self)
            }()

            storageCampaign.update(with: campaign)
        }
    }
}

// MARK: - Synchronize target devices
private extension BlazeStore {

    func synchronizeTargetDevices(siteID: Int64, locale: String, onCompletion: @escaping (Result<[BlazeTargetDevice], Error>) -> Void) {
        Task { @MainActor in
            do {
                let stubbedResult = [
                    BlazeTargetDevice(id: "mobile", name: "Mobile", locale: locale),
                    BlazeTargetDevice(id: "desktop", name: "Desktop", locale: locale)
                ]
                // TODO-11540: remove stubbed result when the API is ready.
                let devices: [BlazeTargetDevice] = try await mockResponse(stubbedResult: stubbedResult, onExecution: {
                    try await remote.fetchTargetDevices(for: siteID, locale: locale)
                })
                insertStoredTargetDevicesInBackground(readonlyDevices: devices, locale: locale) {
                    onCompletion(.success(devices))
                }
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Removes BlazeTargetDevice entities with the given locale
    /// and inserts specified BlazeTargetDevice Entities in a background thread.
    /// `onCompletion` will be called on the main thread.
    ///
    func insertStoredTargetDevicesInBackground(readonlyDevices: [Networking.BlazeTargetDevice],
                                               locale: String,
                                               onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            derivedStorage.deleteBlazeTargetDevices(locale: locale)
            for device in readonlyDevices {
                let storageDevice = derivedStorage.insertNewObject(ofType: Storage.BlazeTargetDevice.self)
                storageDevice.update(with: device)
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}

// MARK: - Helper for mocking response
private extension BlazeStore {
    static var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }

    func mockResponse<T>(stubbedResult: T, onExecution: () async throws -> T) async throws -> T {
        // skips stubbed result for unit tests
        guard Self.isRunningTests else {
            return stubbedResult
        }
        return try await onExecution()
    }
}
