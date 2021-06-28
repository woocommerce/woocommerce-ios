import Foundation
import Networking
import Storage

// MARK: - DataStore
//
public final class DataStore: Store {
    private let remote: DataRemote

    /// Shared private StorageType for use during then entire DataStore sync process
    ///
    private lazy var sharedDerivedStorage: StorageType = {
        storageManager.writerDerivedStorage
    }()

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = DataRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, remote: DataRemote) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: DataAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? DataAction else {
            assertionFailure("DataStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeCountries(let siteID, let onCompletion):
            synchronizeCountries(siteID: siteID, completion: onCompletion)
        }
    }
}

private extension DataStore {

    func synchronizeCountries(siteID: Int64,
                              completion: @escaping (Result<[WooCountry], Error>) -> Void) {
        remote.loadCountries(siteID: siteID) { [weak self] (result) in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let countries):
                self.insertCountriesInBackground(countries: countries) {
                    completion(.success(countries))
                }
            }
        }
    }

}

private extension DataStore {

    /// Inserts the specified readonly WooCountry entity *in a background thread*.
    /// `onCompletion` will be called on the main thread!
    ///
    func insertCountriesInBackground(countries: [WooCountry], onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            self?.insertCountries(countries: countries, in: derivedStorage)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Delete and re-inserts the specified readonly WooCountry entities in the current thread.
    func insertCountries(countries: [WooCountry], in storage: StorageType) {
        // We remove any objects that exist in storage
        storage.deleteAllObjects(ofType: Storage.WooCountry.self)

        // We add the new entities
        for country in countries {
            let newStorageCountry = storage.insertNewObject(ofType: Storage.WooCountry.self)
            newStorageCountry.update(with: country)
            for state in country.states {
                let newStorageState = storage.insertNewObject(ofType: Storage.StateOfAWooCountry.self)
                newStorageState.update(with: state)
                newStorageCountry.addToStates(newStorageState)
            }
        }
    }
}
