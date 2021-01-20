import Foundation
import Networking
import Storage

// MARK: - ProductVariationStore
//
public final class ProductVariationStore: Store {
    private let remote: ProductVariationsRemoteProtocol

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

    public override convenience init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        let remote = ProductVariationsRemote(network: network)
        self.init(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
    }

    init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, remote: ProductVariationsRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

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
        case .retrieveProductVariation(let siteID, let productID, let variationID, let onCompletion):
            retrieveProductVariation(siteID: siteID, productID: productID, variationID: variationID, onCompletion: onCompletion)
        case .createProductVariation(let siteID, let productID, let newVariation, let onCompletion):
            createProductVariation(siteID: siteID, productID: productID, newVariation: newVariation, onCompletion: onCompletion)
        case .updateProductVariation(let productVariation, let onCompletion):
            updateProductVariation(productVariation: productVariation, onCompletion: onCompletion)
        case .requestMissingVariations(let order, let onCompletion):
            requestMissingVariations(for: order, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension ProductVariationStore {

    /// Synchronizes the product reviews associated with a given Site ID (if any!).
    ///
    func synchronizeProductVariations(siteID: Int64, productID: Int64, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Error?) -> Void) {
        remote.loadAllProductVariations(for: siteID,
                                        productID: productID,
                                        context: nil,
                                        pageNumber: pageNumber,
                                        pageSize: pageSize) { [weak self] (productVariations, error) in
            guard let productVariations = productVariations else {
                onCompletion(error)
                return
            }

            if pageNumber == Default.firstPageNumber {
                self?.deleteStoredProductVariations(siteID: siteID,
                                                    productID: productID)
            }

            self?.upsertStoredProductVariationsInBackground(readOnlyProductVariations: productVariations,
                                                            siteID: siteID,
                                                            productID: productID) {
                onCompletion(nil)
            }
        }
    }

    /// Retrieves the product variation associated with a given siteID + productID + variationID.
    ///
    func retrieveProductVariation(siteID: Int64, productID: Int64, variationID: Int64,
                                  onCompletion: @escaping (Result<ProductVariation, Error>) -> Void) {
        remote.loadProductVariation(for: siteID, productID: productID, variationID: variationID) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))
            case .success(let productVariation):
                self.upsertStoredProductVariationsInBackground(readOnlyProductVariations: [productVariation],
                                                               siteID: siteID, productID: productID) { [weak self] in
                   guard let storageProductVariation = self?.storageManager.viewStorage
                        .loadProductVariation(siteID: productVariation.siteID,
                                              productVariationID: productVariation.productVariationID) else {
                                                onCompletion(.failure(ProductVariationLoadError.notFoundInStorage))
                                                return
                    }
                    onCompletion(.success(storageProductVariation.toReadOnly()))
                }
            }
        }
    }

    func createProductVariation(siteID: Int64,
                                 productID: Int64,
                                 newVariation: CreateProductVariation,
                                 onCompletion: @escaping (Result<ProductVariation, Error>) -> Void) {
        remote.createProductVariation(for: siteID, productID: productID, newVariation: newVariation) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))
            case .success(let productVariation):
                self.upsertStoredProductVariationsInBackground(readOnlyProductVariations: [productVariation],
                                                               siteID: siteID,
                                                               productID: productID) { [weak self] in
                    guard let storageProductVariation = self?.storageManager.viewStorage.loadProductVariation(siteID: siteID,
                                                                      productVariationID: productVariation.productVariationID
                    )
                    else {
                                                onCompletion(.failure(ProductVariationLoadError.notFoundInStorage))
                                                return
                    }
                    onCompletion(.success(storageProductVariation.toReadOnly()))
                }
            }
        }
    }

    /// Updates the product variation.
    ///
    func updateProductVariation(productVariation: ProductVariation, onCompletion: @escaping (Result<ProductVariation, ProductUpdateError>) -> Void) {
        remote.updateProductVariation(productVariation: productVariation) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .failure(let error):
                onCompletion(.failure(ProductUpdateError(error: error)))
            case .success(let productVariation):
                self.upsertStoredProductVariationsInBackground(readOnlyProductVariations: [productVariation],
                                                               siteID: productVariation.siteID,
                                                               productID: productVariation.productID) { [weak self] in
                                                                guard let storageProductVariation = self?.storageManager.viewStorage
                                                                    .loadProductVariation(siteID: productVariation.siteID,
                                                                                          productVariationID: productVariation.productVariationID) else {
                                                                                            onCompletion(.failure(.notFoundInStorage))
                                                                                            return
                                                                }
                                                                onCompletion(.success(storageProductVariation.toReadOnly()))
                }
            }
        }
    }

    /// Synchronizes the variations in a specified Order that have not been fetched yet.
    ///
    func requestMissingVariations(for order: Order, onCompletion: @escaping (Error?) -> Void) {
        let orderItems = order.items

        let storage = storageManager.viewStorage
        let orderItemsWithMissingVariations = orderItems
            .filter { $0.variationID != 0 }
            .filter { storage.loadProductVariation(siteID: order.siteID, productVariationID: $0.variationID) == nil }

        var results = [Result<ProductVariation, Error>]()
        let group = DispatchGroup()
        orderItemsWithMissingVariations.forEach { orderItem in
            group.enter()
            remote.loadProductVariation(for: order.siteID,
                                        productID: orderItem.productID,
                                        variationID: orderItem.variationID) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    results.append(.failure(error))
                    group.leave()
                case .success(let productVariation):
                    self.upsertStoredProductVariationsInBackground(readOnlyProductVariations: [productVariation],
                                                                   siteID: order.siteID,
                                                                   productID: orderItem.productID) {
                        results.append(.success(productVariation))
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: .main) {
            guard results.contains(where: { $0.failure != nil }) == false else {
                onCompletion(ProductVariationLoadError.requestMissingVariations)
                return
            }
            onCompletion(nil)
        }
    }
}


// MARK: - Storage: ProductVariation
//
private extension ProductVariationStore {

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
}

public enum ProductVariationLoadError: Error, Equatable {
    case notFoundInStorage
    case unexpected
    case requestMissingVariations
}
