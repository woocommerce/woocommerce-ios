import Foundation
import Networking
import Storage


// MARK: - ProductStore
//
public class ProductStore: Store {

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
        guard let action = action as? ProductAction else {
            assertionFailure("ProductStore received an unsupported action")
            return
        }

        switch action {
        case .resetStoredProducts(let onCompletion):
            resetStoredProducts(onCompletion: onCompletion)
        case .retrieveProduct(let siteID, let productID, let onCompletion):
            retrieveProduct(siteID: siteID, productID: productID, onCompletion: onCompletion)
        case .synchronizeProducts(let siteID, let pageNumber, let pageSize, let onCompletion):
            synchronizeProducts(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension ProductStore {

    /// Nukes all of the Stored Products.
    ///
    func resetStoredProducts(onCompletion: () -> Void) {
        let storage = storageManager.viewStorage
        storage.deleteAllObjects(ofType: Storage.Product.self)
        storage.saveIfNeeded()
        DDLogDebug("Products deleted")

        onCompletion()
    }

    /// Retrieves the products associated with a given Site ID (if any!).
    ///
    func synchronizeProducts(siteID: Int, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = ProductsRemote(network: network)

        remote.loadAllProducts(for: siteID, pageNumber: pageNumber, pageSize: pageSize) { [weak self] (products, error) in
            guard let products = products else {
                onCompletion(error)
                return
            }

            self?.upsertStoredProductsInBackground(readOnlyProducts: products) {
                onCompletion(nil)
            }
        }
    }

    /// Retrieves the product associated with a given siteID + productID (if any!).
    ///
    func retrieveProduct(siteID: Int, productID: Int, onCompletion: @escaping (Networking.Product?, Error?) -> Void) {
        let remote = ProductsRemote(network: network)

        remote.loadProduct(for: siteID, productID: productID) { [weak self] (product, error) in
            guard let product = product else {
                if case NetworkError.notFound? = error {
                    self?.deleteStoredProduct(siteID: siteID, productID: productID)
                }
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredProductsInBackground(readOnlyProducts: [product]) {
                onCompletion(product, nil)
            }
        }
    }
}


// MARK: - Storage
//
private extension ProductStore {

    /// Deletes any Storage.Product with the specified OrderID
    ///
    func deleteStoredProduct(siteID: Int, productID: Int) {
        let storage = storageManager.viewStorage
        guard let product = storage.loadProduct(siteID: siteID, productID: productID) else {
            return
        }

        storage.deleteObject(product)
        storage.saveIfNeeded()
    }

    /// Updates (OR Inserts) the specified ReadOnly Product Entities *in a background thread*. onCompletion will be called
    /// on the main thread!
    ///
    func upsertStoredProductsInBackground(readOnlyProducts: [Networking.Product], onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            self.upsertStoredProducts(readOnlyProducts: readOnlyProducts, in: derivedStorage)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly Product Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyProducts: Remote Products to be persisted.
    ///     - storage: Where we should save all the things!
    ///
    func upsertStoredProducts(readOnlyProducts: [Networking.Product], in storage: StorageType) {
        for readOnlyProduct in readOnlyProducts {
            let storageProduct = storage.loadProduct(siteID: readOnlyProduct.siteID, productID: readOnlyProduct.productID) ??
                storage.insertNewObject(ofType: Storage.Product.self)

            storageProduct.update(with: readOnlyProduct)
            handleProductDimensions(readOnlyProduct, storageProduct, storage)
            handleProductAttributes(readOnlyProduct, storageProduct, storage)
            handleProductDefaultAttributes(readOnlyProduct, storageProduct, storage)
            handleProductImages(readOnlyProduct, storageProduct, storage)
            handleProductCategories(readOnlyProduct, storageProduct, storage)
            handleProductTags(readOnlyProduct, storageProduct, storage)
        }
    }

    /// Updates or inserts the provided StorageProduct's dimensions using the provided read-only Product's dimensions
    ///
    func handleProductDimensions(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        if let existingStorageDimensions = storageProduct.dimensions {
            existingStorageDimensions.update(with: readOnlyProduct.dimensions)
        } else {
            let newStorageDimensions = storage.insertNewObject(ofType: Storage.ProductDimensions.self)
            newStorageDimensions.update(with: readOnlyProduct.dimensions)
            storageProduct.dimensions = newStorageDimensions
        }
    }

    /// Updates, inserts, or prunes the provided StorageProduct's attributes using the provided read-only Product's attributes
    ///
    func handleProductAttributes(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        // Upsert the attributes from the read-only product
        for readOnlyAttribute in readOnlyProduct.attributes {
            if let existingStorageAttribute = storage.loadProductAttribute(attributeID: readOnlyAttribute.attributeID) {
                existingStorageAttribute.update(with: readOnlyAttribute)
            } else {
                let newStorageAttribute = storage.insertNewObject(ofType: Storage.ProductAttribute.self)
                newStorageAttribute.update(with: readOnlyAttribute)
                storageProduct.addToAttributes(newStorageAttribute)
            }
        }

        // Now, remove any objects that exist in storageProduct.attributes but not in readOnlyProduct.attributes
        storageProduct.attributes?.forEach { storageAttribute in
            if readOnlyProduct.attributes.first(where: { $0.attributeID == storageAttribute.attributeID } ) == nil {
                storageProduct.removeFromAttributes(storageAttribute)
                storage.deleteObject(storageAttribute)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageProduct's default attributes using the provided read-only Product's default attributes
    ///
    func handleProductDefaultAttributes(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        // Upsert the default attributes from the read-only product
        for readOnlyDefaultAttribute in readOnlyProduct.defaultAttributes {
            if let existingStorageDefaultAttribute = storage.loadProductDefaultAttribute(defaultAttributeID: readOnlyDefaultAttribute.attributeID) {
                existingStorageDefaultAttribute.update(with: readOnlyDefaultAttribute)
            } else {
                let newStorageDefaultAttribute = storage.insertNewObject(ofType: Storage.ProductDefaultAttribute.self)
                newStorageDefaultAttribute.update(with: readOnlyDefaultAttribute)
                storageProduct.addToDefaultAttributes(newStorageDefaultAttribute)
            }
        }

        // Now, remove any objects that exist in storageProduct.defaultAttributes but not in readOnlyProduct.defaultAttributes
        storageProduct.defaultAttributes?.forEach { storageDefaultAttribute in
            if readOnlyProduct.defaultAttributes.first(where: { $0.attributeID == storageDefaultAttribute.attributeID } ) == nil {
                storageProduct.removeFromDefaultAttributes(storageDefaultAttribute)
                storage.deleteObject(storageDefaultAttribute)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageProduct's images using the provided read-only Product's images
    ///
    func handleProductImages(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        // Upsert the images from the read-only product
        for readOnlyImage in readOnlyProduct.images {
            if let existingStorageImage = storage.loadProductImage(imageID: readOnlyImage.imageID) {
                existingStorageImage.update(with: readOnlyImage)
            } else {
                let newStorageImage = storage.insertNewObject(ofType: Storage.ProductImage.self)
                newStorageImage.update(with: readOnlyImage)
                storageProduct.addToImages(newStorageImage)
            }
        }

        // Now, remove any objects that exist in storageProduct.images but not in readOnlyProduct.images
        storageProduct.images?.forEach { storageImage in
            if readOnlyProduct.images.first(where: { $0.imageID == storageImage.imageID } ) == nil {
                storageProduct.removeFromImages(storageImage)
                storage.deleteObject(storageImage)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageProduct's categories using the provided read-only Product's categories
    ///
    func handleProductCategories(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        // Upsert the categories from the read-only product
        for readOnlyCategory in readOnlyProduct.categories {
            if let existingStorageCategory = storage.loadProductCategory(categoryID: readOnlyCategory.categoryID) {
                existingStorageCategory.update(with: readOnlyCategory)
            } else {
                let newStorageCategory = storage.insertNewObject(ofType: Storage.ProductCategory.self)
                newStorageCategory.update(with: readOnlyCategory)
                storageProduct.addToCategories(newStorageCategory)
            }
        }

        // Now, remove any objects that exist in storageProduct.categories but not in readOnlyProduct.categories
        storageProduct.categories?.forEach { storageCategory in
            if readOnlyProduct.categories.first(where: { $0.categoryID == storageCategory.categoryID } ) == nil {
                storageProduct.removeFromCategories(storageCategory)
                storage.deleteObject(storageCategory)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageProduct's tags using the provided read-only Product's tags
    ///
    func handleProductTags(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        // Upsert the tags from the read-only product
        for readOnlyTag in readOnlyProduct.tags {
            if let existingStorageTag = storage.loadProductTag(tagID: readOnlyTag.tagID) {
                existingStorageTag.update(with: readOnlyTag)
            } else {
                let newStorageTag = storage.insertNewObject(ofType: Storage.ProductTag.self)
                newStorageTag.update(with: readOnlyTag)
                storageProduct.addToTags(newStorageTag)
            }
        }

        // Now, remove any objects that exist in storageProduct.tags but not in readOnlyProduct.tags
        storageProduct.tags?.forEach { storageTag in
            if readOnlyProduct.tags.first(where: { $0.tagID == storageTag.tagID } ) == nil {
                storageProduct.removeFromTags(storageTag)
                storage.deleteObject(storageTag)
            }
        }
    }
}


// MARK: - Unit Testing Helpers
//
extension ProductStore {

    /// Unit Testing Helper: Updates or Inserts the specified ReadOnly Product in a given Storage Layer.
    ///
    func upsertStoredProduct(readOnlyProduct: Networking.Product, in storage: StorageType) {
        upsertStoredProducts(readOnlyProducts: [readOnlyProduct], in: storage)
    }
}
