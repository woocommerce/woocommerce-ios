import Foundation
import Networking
import Storage

/// Describes a class/struct that can be used to request a tax class remotely.
public protocol TaxClassRequestable {
    var siteID: Int64 { get }
    var taxClass: String? { get }
}

extension Product: TaxClassRequestable {}

extension ProductVariation: TaxClassRequestable {}

// MARK: - TaxStore
//
public class TaxStore: Store {
    private let remote: TaxRemote

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = TaxRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: TaxAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? TaxAction else {
            assertionFailure("TaxClassStore received an unsupported action")
            return
        }

        switch action {
        case .retrieveTaxClasses(let siteID, let onCompletion):
            retrieveTaxClasses(siteID: siteID, onCompletion: onCompletion)
        case .requestMissingTaxClasses(let product, let onCompletion):
            requestMissingTaxClasses(for: product, onCompletion: onCompletion)
        case let .retrieveTaxRates(siteID, pageNumber, pageSize, onCompletion):
            retrieveTaxRates(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        case .retrieveTaxRate(siteID: let siteID, taxRateID: let taxRateID, onCompletion: let onCompletion):
            retrieveTaxRate(siteID: siteID, taxRateID: taxRateID, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension TaxStore {

    /// Retrieve and synchronizes the Tax Classes associated with a given Site ID (if any!).
    ///
    func retrieveTaxClasses(siteID: Int64, onCompletion: @escaping ([TaxClass]?, Error?) -> Void) {
        remote.loadAllTaxClasses(for: siteID) { [weak self] (taxClasses, error) in
            guard let taxClasses = taxClasses else {
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredTaxClassesInBackground(readOnlyTaxClasses: taxClasses) {
                onCompletion(taxClasses, nil)
            }
        }
    }

    /// Synchronizes the Tax Class found in a specified Product.
    ///
    func requestMissingTaxClasses(for taxClassRequestable: TaxClassRequestable, onCompletion: @escaping (TaxClass?, Error?) -> Void) {
        guard let taxClassFromStorage = taxClassRequestable.taxClass, taxClassRequestable.taxClass?.isEmpty == false else {
            onCompletion(nil, nil)
            return
        }

        let storage = storageManager.viewStorage

        if let storageTaxClass = storage.loadTaxClass(slug: taxClassFromStorage) {
            onCompletion(storageTaxClass.toReadOnly(), nil)
            return
        }
        else {
            remote.loadAllTaxClasses(for: taxClassRequestable.siteID) { [weak self] (taxClasses, error) in
                guard let taxClasses = taxClasses else {
                    onCompletion(nil, error)
                    return
                }

                self?.upsertStoredTaxClassesInBackground(readOnlyTaxClasses: taxClasses) {
                    let taxClass = taxClasses.first(where: { $0.slug == taxClassRequestable.taxClass } )
                    onCompletion(taxClass, nil)
                }
            }
        }
    }

    func retrieveTaxRates(siteID: Int64,
                          pageNumber: Int,
                          pageSize: Int,
                          onCompletion: @escaping (Result<[TaxRate], Error>) -> Void) {
        remote.retrieveTaxRates(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize) { [weak self] result in
            switch result {
            case .success(let taxRates):
                self?.upsertStoredTaxRatesInBackground(readOnlyTaxRates: taxRates, siteID: siteID, shouldDeleteExistingTaxRates: pageNumber == 1) {
                    onCompletion(.success(taxRates))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    func retrieveTaxRate(siteID: Int64,
                          taxRateID: Int64,
                          onCompletion: @escaping (Result<TaxRate, Error>) -> Void) {
        remote.retrieveTaxRate(siteID: siteID, taxRateID: taxRateID) { [weak self] result in
            switch result {
            case .success(let taxRate):
                self?.upsertStoredTaxRatesInBackground(readOnlyTaxRates: [taxRate], siteID: siteID, shouldDeleteExistingTaxRates: false) {
                    onCompletion(.success(taxRate))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }
}


// MARK: - Storage: TaxClass
//
private extension TaxStore {

    /// Updates (OR Inserts) the specified ReadOnly TaxClass Entities *in a background thread*. onCompletion will be called
    /// on the main thread!
    ///
    func upsertStoredTaxClassesInBackground(readOnlyTaxClasses: [Networking.TaxClass], onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            self.upsertStoredTaxClasses(readOnlyTaxClasses: readOnlyTaxClasses, in: derivedStorage)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly TaxClass Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyTaxClasses: Remote TaxClass to be persisted.
    ///     - storage: Where we should save all the things!
    ///
    func upsertStoredTaxClasses(readOnlyTaxClasses: [Networking.TaxClass], in storage: StorageType) {
        storage.deleteAllObjects(ofType: Storage.TaxClass.self)
        for readOnlyTaxClass in readOnlyTaxClasses {
            let storageTaxClass = storage.insertNewObject(ofType: Storage.TaxClass.self)
            storageTaxClass.update(with: readOnlyTaxClass)
        }
    }
}

// MARK: - Storage: TaxRate
//
private extension TaxStore {

    /// Updates (OR Inserts) the specified ReadOnly TaxRate Entities *in a background thread*. onCompletion will be called
    /// on the main thread!
    ///
    func upsertStoredTaxRatesInBackground(readOnlyTaxRates: [Networking.TaxRate],
                                          siteID: Int64,
                                          shouldDeleteExistingTaxRates: Bool,
                                          onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            guard let self = self else { return }

            if shouldDeleteExistingTaxRates {
                derivedStorage.deleteTaxRates(siteID: siteID)
            }

            self.upsertStoredTaxRates(readOnlyTaxRates: readOnlyTaxRates, siteID: siteID, in: derivedStorage)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly TaxRate Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyTaxRates: Remote TaxRate to be persisted.
    ///     - siteID: The site id of the tax rate
    ///     - storage: Where we should save all the things!
    ///
    func upsertStoredTaxRates(readOnlyTaxRates: [Networking.TaxRate], siteID: Int64, in storage: StorageType) {
        for readOnlyTaxRate in readOnlyTaxRates {
            let storageTaxRate: Storage.TaxRate = {
                if let storedTaxRate = storage.loadTaxRate(siteID: siteID,
                                                           taxRateID: readOnlyTaxRate.id) {
                    return storedTaxRate
                }

                return storage.insertNewObject(ofType: Storage.TaxRate.self)
            }()

            storageTaxRate.update(with: readOnlyTaxRate)
            storageTaxRate.siteID = siteID
        }
    }
}

// MARK: - Unit Testing Helpers
//
extension TaxStore {

    /// Unit Testing Helper: Updates or Inserts the specified ReadOnly Product in a given Storage Layer.
    ///
    func upsertStoredTaxClass(readOnlyTaxClass: Networking.TaxClass, in storage: StorageType) {
        upsertStoredTaxClasses(readOnlyTaxClasses: [readOnlyTaxClass], in: storage)
    }
}
