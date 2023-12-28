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
        case let .synchronizeTargetLanguages(siteID, locale, onCompletion):
            synchronizeTargetLanguages(siteID: siteID, locale: locale, onCompletion: onCompletion)
        case let .synchronizeTargetTopics(siteID, locale, onCompletion):
            synchronizeTargetTopics(siteID: siteID, locale: locale, onCompletion: onCompletion)
        case let .fetchTargetLocations(siteID, query, locale, onCompletion):
            fetchTargetLocations(siteID: siteID, query: query, locale: locale, onCompletion: onCompletion)
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

// MARK: - Synchronize target languages
private extension BlazeStore {
    func synchronizeTargetLanguages(siteID: Int64,
                                    locale: String,
                                    onCompletion: @escaping (Result<[BlazeTargetLanguage], Error>) -> Void) {
        Task { @MainActor in
            do {
                let stubbedResult = [
                    BlazeTargetLanguage(id: "en", name: "English", locale: locale),
                    BlazeTargetLanguage(id: "es", name: "Spanish", locale: locale)
                ]
                // TODO-11540: remove stubbed result when the API is ready.
                let languages: [BlazeTargetLanguage] = try await mockResponse(stubbedResult: stubbedResult, onExecution: {
                    try await remote.fetchTargetLanguages(for: siteID, locale: locale)
                })
                insertStoredTargetLanguagesInBackground(readonlyLanguages: languages, locale: locale) {
                    onCompletion(.success(languages))
                }
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Removes BlazeTargetLanguage entities with the given locale
    /// and inserts specified BlazeTargetLanguage Entities in a background thread.
    /// `onCompletion` will be called on the main thread.
    ///
    func insertStoredTargetLanguagesInBackground(readonlyLanguages: [Networking.BlazeTargetLanguage],
                                                 locale: String,
                                                 onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            derivedStorage.deleteBlazeTargetLanguages(locale: locale)
            for language in readonlyLanguages {
                let storageDevice = derivedStorage.insertNewObject(ofType: Storage.BlazeTargetLanguage.self)
                storageDevice.update(with: language)
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}

// MARK: - Synchronize target topics
private extension BlazeStore {
    func synchronizeTargetTopics(siteID: Int64,
                                 locale: String,
                                 onCompletion: @escaping (Result<[BlazeTargetTopic], Error>) -> Void) {
        Task { @MainActor in
            do {
                let stubbedResult = [
                    BlazeTargetTopic(id: "IAB1", description: "Arts & Entertainment", locale: locale),
                    BlazeTargetTopic(id: "IAB2", description: "Automotive", locale: locale)
                ]
                // TODO-11540: remove stubbed result when the API is ready.
                let topics: [BlazeTargetTopic] = try await mockResponse(stubbedResult: stubbedResult, onExecution: {
                    try await remote.fetchTargetTopics(for: siteID, locale: locale)
                })
                insertStoredTargetTopicsInBackground(readonlyTopics: topics, locale: locale) {
                    onCompletion(.success(topics))
                }
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Removes BlazeTargetTopic entities with the given locale
    /// and inserts specified BlazeTargetTopic Entities in a background thread.
    /// `onCompletion` will be called on the main thread.
    ///
    func insertStoredTargetTopicsInBackground(readonlyTopics: [Networking.BlazeTargetTopic],
                                              locale: String,
                                              onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            derivedStorage.deleteBlazeTargetTopics(locale: locale)
            for topic in readonlyTopics {
                let storageTopic = derivedStorage.insertNewObject(ofType: Storage.BlazeTargetTopic.self)
                storageTopic.update(with: topic)
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}

// MARK: - Fetch target location by keyword
private extension BlazeStore {
    func fetchTargetLocations(siteID: Int64,
                              query: String,
                              locale: String,
                              onCompletion: @escaping (Result<[BlazeTargetLocation], Error>) -> Void) {
        Task { @MainActor in
            do {
                let locations = try await remote.fetchTargetLocations(for: siteID, query: query, locale: locale)
                onCompletion(.success(locations))
            } catch {
                onCompletion(.failure(error))
            }
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
