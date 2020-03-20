import Foundation
import Networking
import Storage


// MARK: - TaxClassStore
//
public class TaxClassStore: Store {

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: TaxClassAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? TaxClassAction else {
            assertionFailure("TaxClassStore received an unsupported action")
            return
        }

        switch action {
        case .retrieveTaxClasses(let siteID, let onCompletion):
            retrieveTaxClasses(siteID: siteID, onCompletion: onCompletion)
        case .requestMissingTaxClasses(let product, let onCompletion):
            requestMissingTaxClasses(for: product, onCompletion: onCompletion)
        }

    }
}


// MARK: - Services!
//
private extension TaxClassStore {

    /// Retrieve and synchronizes the Tax Classes associated with a given Site ID (if any!).
    ///
    func retrieveTaxClasses(siteID: Int64, onCompletion: @escaping ([TaxClass]?, Error?) -> Void) {
        let remote = TaxClassRemote(network: network)

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
    func requestMissingTaxClasses(for product: Product, onCompletion: @escaping (TaxClass?, Error?) -> Void) {
        guard let taxClassFromStorage = product.taxClass, product.taxClass?.isEmpty == false else {
            onCompletion(nil, nil)
            return
        }

        let storage = storageManager.viewStorage

        if let storageTaxClass = storage.loadTaxClass(slug: taxClassFromStorage) {
            onCompletion(storageTaxClass.toReadOnly(), nil)
            return
        }
        else {
            let remote = TaxClassRemote(network: network)
            remote.loadAllTaxClasses(for: product.siteID) { [weak self] (taxClasses, error) in
                guard let taxClasses = taxClasses else {
                    onCompletion(nil, error)
                    return
                }

                self?.upsertStoredTaxClassesInBackground(readOnlyTaxClasses: taxClasses) {
                    let taxClass = taxClasses.first(where: { $0.slug == product.taxClass } )
                    onCompletion(taxClass, nil)
                }
            }
        }
    }
}


// MARK: - Storage: TaxClass
//
private extension TaxClassStore {

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


// MARK: - Unit Testing Helpers
//
extension TaxClassStore {

    /// Unit Testing Helper: Updates or Inserts the specified ReadOnly Product in a given Storage Layer.
    ///
    func upsertStoredTaxClass(readOnlyTaxClass: Networking.TaxClass, in storage: StorageType) {
        upsertStoredTaxClasses(readOnlyTaxClasses: [readOnlyTaxClass], in: storage)
    }
}
