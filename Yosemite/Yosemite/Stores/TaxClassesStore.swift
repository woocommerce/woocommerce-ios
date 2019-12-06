import Foundation
import Networking
import Storage


// MARK: - TaxClassesStore
//
public class TaxClassesStore: Store {

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ProductAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? TaxClassesAction else {
            assertionFailure("TaxClassesStore received an unsupported action")
            return
        }
        
        switch action {
        case .retriveTaxClasses(let siteID, let onCompletion):
            retriveTaxClasses(siteID: siteID, onCompletion: onCompletion)
        case .resetStoredTaxClasses(let onCompletion):
            resetStoredTaxClasses(onCompletion: onCompletion)
        case .requestMissingTaxClasses(let product, let onCompletion):
            requestMissingTaxClasses(for: product, onCompletion: onCompletion)
        }

    }
}


// MARK: - Services!
//
private extension TaxClassesStore {

    /// Retrieve and synchronizes the Tax Classes associated with a given Site ID (if any!).
    ///
    func retriveTaxClasses(siteID: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = TaxClassesRemote(network: network)

        remote.loadAllTaxClasses(for: siteID) { [weak self] (taxClasses, error) in
            guard let taxClasses = taxClasses else {
                onCompletion(error)
                return
            }
            
            self?.upsertStoredTaxClassesInBackground(readOnlyTaxClasses: taxClasses) {
                onCompletion(nil)
            }
        }
    }
    
    /// Deletes all of the Stored TaxClasses.
    ///
    func resetStoredTaxClasses(onCompletion: () -> Void) {
        let storage = storageManager.viewStorage
        storage.deleteAllObjects(ofType: Storage.TaxClass.self)
        storage.saveIfNeeded()
        DDLogDebug("Tax Classes deleted")

        onCompletion()
    }

    /// Synchronizes the Tax Class found in a specified Product.
    ///
    func requestMissingTaxClasses(for product: Product, onCompletion: @escaping (Error?) -> Void) {
        guard let taxClassFromStorage = product.taxClass else {
            onCompletion(nil)
            return
        }
        
        let storage = storageManager.viewStorage
        let storageTaxClass = storage.loadTaxClass(slug: taxClassFromStorage)
        
        if storageTaxClass == nil {
            let remote = TaxClassesRemote(network: network)
            remote.loadAllTaxClasses(for: product.siteID) { [weak self] (taxClasses, error) in
                guard let taxClasses = taxClasses else {
                    onCompletion(error)
                    return
                }
                
                self?.upsertStoredTaxClassesInBackground(readOnlyTaxClasses: taxClasses) {
                    onCompletion(nil)
                }
            }
        }
        else{
            onCompletion(nil)
            return
        }
    }
}


// MARK: - Storage: TaxClass
//
private extension TaxClassesStore {

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
        for readOnlyTaxClass in readOnlyTaxClasses {
            let storageTaxClass = storage.loadTaxClass(slug: readOnlyTaxClass.slug) ?? storage.insertNewObject(ofType: Storage.TaxClass.self)
            
            storageTaxClass.update(with: readOnlyTaxClass)
        }
    }

}


// MARK: - Unit Testing Helpers
//
extension TaxClassesStore {

    /// Unit Testing Helper: Updates or Inserts the specified ReadOnly Product in a given Storage Layer.
    ///
    func upsertStoredTaxClass(readOnlyTaxClass: Networking.TaxClass, in storage: StorageType) {
        upsertStoredTaxClasses(readOnlyTaxClasses: [readOnlyTaxClass], in: storage)
    }
}
