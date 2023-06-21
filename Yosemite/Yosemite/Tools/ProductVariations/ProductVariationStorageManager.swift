import Foundation
import Networking
import Storage

final class ProductVariationStorageManager {
    private let storageManager: StorageManagerType

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    init(storageManager: StorageManagerType) {
        self.storageManager = storageManager
    }

    /// Updates (OR Inserts) the specified ReadOnly ProductReview Entities *in a background thread*. onCompletion will be called
    /// on the main thread!
    ///
    func upsertStoredProductVariationsInBackground(readOnlyProductVariations: [Networking.ProductVariation],
                                                   siteID: Int64,
                                                   productID: Int64,
                                                   onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            self?.upsertStoredProductVariations(readOnlyProductVariations: readOnlyProductVariations, in: derivedStorage, siteID: siteID, productID: productID)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Deletes any Storage.ProductVariation with the specified `siteID` and `productID`
    ///
    func deleteStoredProductVariations(siteID: Int64, productID: Int64) {
        let storage = storageManager.viewStorage
        storage.deleteProductVariations(siteID: siteID, productID: productID)
        storage.saveIfNeeded()
    }

    /// Deletes any Storage.ProductVariation with the specified `siteID` and `productID`
    ///
    func deleteStoredProductVariation(siteID: Int64, productVariationID: Int64) {
        let storage = storageManager.viewStorage
        storage.deleteProductVariation(siteID: siteID, productVariationID: productVariationID)
        storage.saveIfNeeded()
    }

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
        let product = storage.loadProduct(siteID: siteID, productID: productID)

        // Upserts the Product Variations from the read-only version
        for readOnlyProductVariation in readOnlyProductVariations {
            let storageProductVariation = storage.loadProductVariation(siteID: siteID,
                                                                       productVariationID: readOnlyProductVariation.productVariationID)
            ?? storage.insertNewObject(ofType: Storage.ProductVariation.self)
            storageProductVariation.update(with: readOnlyProductVariation)
            storageProductVariation.product = product
            handleProductDimensions(readOnlyProductVariation, storageProductVariation, storage)
            handleProductVariationAttributes(readOnlyProductVariation, storageProductVariation, storage)
            handleProductImage(readOnlyProductVariation, storageProductVariation, storage)
            handleProductSubscription(readOnlyProductVariation, storageProductVariation, storage)
        }
    }
}

private extension ProductVariationStorageManager {
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
    /// Because all local Product attributes have ID: Int64 = 0, they are not unique in Storage and we always replace the whole
    /// attribute array.
    ///
    func handleProductVariationAttributes(_ readOnlyVariation: Networking.ProductVariation,
                                          _ storageVariation: Storage.ProductVariation,
                                          _ storage: StorageType) {
        // Removes all the attributes first.
        storageVariation.attributesArray.forEach { existingStorageAttribute in
            storage.deleteObject(existingStorageAttribute)
        }

        // Inserts the attributes from the read-only product variation.
        var storageAttributes = [StorageAttribute]()
        for readOnlyAttribute in readOnlyVariation.attributes {
            let newStorageAttribute = storage.insertNewObject(ofType: Storage.GenericAttribute.self)
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

    /// Updates, inserts, or prunes the provided StorageProductVariation's subscription using the provided read-only ProductVariation's subscription
    ///
    func handleProductSubscription(_ readOnlyVariation: Networking.ProductVariation, _ storageVariation: Storage.ProductVariation, _ storage: StorageType) {
        guard let readOnlySubscription = readOnlyVariation.subscription else {
            if let existingStorageSubscription = storageVariation.subscription {
                storage.deleteObject(existingStorageSubscription)
            }
            return
        }

        if let existingStorageSubscription = storageVariation.subscription {
            existingStorageSubscription.update(with: readOnlySubscription)
        } else {
            let newStorageSubscription = storage.insertNewObject(ofType: Storage.ProductSubscription.self)
            newStorageSubscription.update(with: readOnlySubscription)
            storageVariation.subscription = newStorageSubscription
        }
    }
}
