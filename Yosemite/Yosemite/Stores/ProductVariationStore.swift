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
            assertionFailure("ProductReviewStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeProductVariations(let siteID, let productID, let pageNumber, let pageSize, let onCompletion):
            synchronizeProductVariations(siteID: siteID, productID: productID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension ProductVariationStore {

    /// Synchronizes the product reviews associated with a given Site ID (if any!).
    ///
    func synchronizeProductVariations(siteID: Int64, productID: Int64, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = ProductVariationsRemote(network: network)

        remote.loadAllProductVariations(for: siteID, productID: productID) { [weak self] (productVariations, error) in
            guard let productVariations = productVariations else {
                onCompletion(error)
                return
            }

            self?.upsertStoredProductVariationsInBackground(readOnlyProductVariations: productVariations, siteID: siteID, productID: productID) {
                onCompletion(nil)
            }
        }
    }
}


// MARK: - Storage: ProductReview
//
private extension ProductVariationStore {

    /// Updates (OR Inserts) the specified ReadOnly ProductReview Entities *in a background thread*. onCompletion will be called
    /// on the main thread!
    ///
    func upsertStoredProductVariationsInBackground(readOnlyProductVariations: [Networking.ProductVariation], siteID: Int64, productID: Int64, onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            self?.upsertStoredProductVariations(readOnlyProductVariations: readOnlyProductVariations, in: derivedStorage, siteID: siteID, productID: productID)
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
    ///     - readOnlyProductVariations: Remote ProductVariation's to be persisted.
    ///     - storage: Where we should save all the things!
    ///     - siteID: site ID for looking up the Product.
    ///     - productID: product ID for looking up the Product.
    ///
    func upsertStoredProductVariations(readOnlyProductVariations: [Networking.ProductVariation],
                                       in storage: StorageType,
                                       siteID: Int64,
                                       productID: Int64) {
        let product = storage.loadProduct(siteID: Int(siteID), productID: Int(productID))

        // Upserts the Product Variations from the read-only version
        for readOnlyProductVariation in readOnlyProductVariations {
            let storageProductVariation = storage.loadProductVariation(siteID: siteID, productVariationID: readOnlyProductVariation.productVariationID) ?? storage.insertNewObject(ofType: Storage.ProductVariation.self)
            storageProductVariation.update(with: readOnlyProductVariation)
            storageProductVariation.product = product
            handleProductDimensions(readOnlyProductVariation, storageProductVariation, storage)
            handleProductVariationAttributes(readOnlyProductVariation, storageProductVariation, storage)
            handleProductImage(readOnlyProductVariation, storageProductVariation, storage)
        }
    }

    /// Updates or inserts the provided StorageProductVariation's dimensions using the provided read-only ProductVariation's dimensions
    ///
    func handleProductDimensions(_ readOnlyVariation: Networking.ProductVariation, _ storageVariation: Storage.ProductVariation, _ storage: StorageType) {
        if let existingStorageDimensions = storageVariation.dimensions {
            existingStorageDimensions.update(with: readOnlyVariation.dimensions)
        } else {
            let newStorageDimensions = storage.insertNewObject(ofType: Storage.ProductDimensions.self)
            newStorageDimensions.update(with: readOnlyVariation.dimensions)
            storageVariation.dimensions = newStorageDimensions
        }
    }

    /// Replaces the provided StorageProductVariation's attributes with the provided read-only
    /// ProductVariation's attributes.
    /// Because all local Product attributes have ID = 0, they are not unique in Storage and we always replace the whole
    /// attribute array.
    ///
    func handleProductVariationAttributes(_ readOnlyVariation: Networking.ProductVariation, _ storageVariation: Storage.ProductVariation, _ storage: StorageType) {

        // Removes all the attributes first.
        storageVariation.attributesArray.forEach { existingStorageAttribute in
            storage.deleteObject(existingStorageAttribute)
        }

        // Inserts the attributes from the read-only product variation.
        var storageAttributes = [StorageAttribute]()
        for readOnlyAttribute in readOnlyVariation.attributes {
            let newStorageAttribute = storage.insertNewObject(ofType: Storage.Attribute.self)
            newStorageAttribute.update(with: readOnlyAttribute)
            storageAttributes.append(newStorageAttribute)
        }
        storageVariation.attributes = NSOrderedSet(array: storageAttributes)
    }

    /// Updates, inserts, or prunes the provided StorageProductVariation's image using the provided read-only ProductVariation's image
    ///
    func handleProductImage(_ readOnlyVariation: Networking.ProductVariation, _ storageVariation: Storage.ProductVariation, _ storage: StorageType) {
        guard let readOnlyImage = readOnlyVariation.image else {
            if let existingStorageImage = storageVariation.image {
                storage.deleteObject(existingStorageImage)
            }
            return
        }

        if let existingStorageImage = storageVariation.image {
            existingStorageImage.update(with: readOnlyImage)
        } else {
            let newStorageImage = storage.insertNewObject(ofType: Storage.ProductImage.self)
            newStorageImage.update(with: readOnlyImage)
            storageVariation.image = newStorageImage
        }
    }
}
