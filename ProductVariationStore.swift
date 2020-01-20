// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation
import Networking
import Storage

// MARK: - ProductVariationStore
//
public final class ProductVariationStore: Store {

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ProductVariationAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? ProductVariationAction else {
            assertionFailure("ProductVariationStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeProductVariationModels(let siteID, let pageNumber, let pageSize, let onCompletion):
            synchronizeProductVariationModels(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension ProductVariationStore {

    /// Synchronizes the `ProductVariation`s associated with a given Site ID (if any!).
    ///
    func synchronizeProductVariationModels(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = ProductVariationRemote(network: network)

        remote.loadAllProductVariationModels(for: siteID) { [weak self] (models, error) in
            guard let models = models else {
                onCompletion(error)
                return
            }

            self?.upsertStoredProductVariationModelsInBackground(readOnlyProductVariationModels: models,
                                                                  siteID: siteID) {
                                                                      onCompletion(nil)
            }
        }
    }
}


// MARK: - Storage: ProductVariation
//
private extension ProductVariationStore {

    /// Updates (OR Inserts) the specified ReadOnly ProductVariation Entities *in a background thread*. onCompletion will be called
    /// on the main thread!
    ///
    func upsertStoredProductVariationModelsInBackground(readOnlyProductVariationModels: [Networking.ProductVariation],
                                                   siteID: Int64,
                                                   onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            self?.upsertStoredProductVariationModels(readOnlyProductVariationModels: readOnlyProductVariationModels, in: derivedStorage, siteID: siteID)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}


private extension ProductVariationStore {
    /// Updates (OR Inserts) the specified ReadOnly ProductVariation Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyProductVariationModels: Remote ProductVariation's to be persisted.
    ///     - storage: Where we should save all the things!
    ///     - siteID: site ID for looking up the ProductVariation.
    ///
    func upsertStoredProductVariationModels(readOnlyProductVariationModels: [Networking.ProductVariation],
                                       in storage: StorageType,
                                       siteID: Int64) {
        // Upserts the ProductVariation models from the read-only version
        for readOnlyProductVariation in readOnlyProductVariationModels {
            let storageProductVariation = storage.loadProductVariation(siteID: siteID,
                                                                            remoteID: readOnlyProductVariation.remoteID)
                ?? storage.insertNewObject(ofType: Storage.ProductVariation.self)
            storageProductVariation.update(with: readOnlyProductVariation)
        }
    }
}
