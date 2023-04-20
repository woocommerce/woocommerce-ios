import Foundation
import Networking
import Storage

// MARK: - ProductVariationStore
//
public final class ProductVariationStore: Store {
    private let remote: ProductVariationsRemoteProtocol

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
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
        case .synchronizeAllProductVariations(let siteID, let productID, let onCompletion):
            synchronizeAllProductVariations(siteID: siteID, productID: productID, onCompletion: onCompletion)
        case .synchronizeProductVariations(let siteID, let productID, let pageNumber, let pageSize, let onCompletion):
            synchronizeProductVariations(siteID: siteID, productID: productID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        case .retrieveProductVariation(let siteID, let productID, let variationID, let onCompletion):
            retrieveProductVariation(siteID: siteID, productID: productID, variationID: variationID, onCompletion: onCompletion)
        case .createProductVariation(let siteID, let productID, let newVariation, let onCompletion):
            createProductVariation(siteID: siteID, productID: productID, newVariation: newVariation, onCompletion: onCompletion)
        case .createProductVariations(let siteID, let productID, let productVariations, let onCompletion):
            createProductVariations(siteID: siteID, productID: productID, productVariations: productVariations, onCompletion: onCompletion)
        case .updateProductVariation(let productVariation, let onCompletion):
            updateProductVariation(productVariation: productVariation, onCompletion: onCompletion)
        case .updateProductVariationImage(let siteID, let productID, let variationID, let image, let completion):
            updateProductVariationImage(siteID: siteID, productID: productID, variationID: variationID, image: image, completion: completion)
        case .requestMissingVariations(let order, let onCompletion):
            requestMissingVariations(for: order, onCompletion: onCompletion)
        case .deleteProductVariation(let productVariation, let onCompletion):
            deleteProductVariation(productVariation: productVariation, onCompletion: onCompletion)
        case .updateProductVariations(let siteID, let productID, let productVariations, onCompletion: let onCompletion):
            updateProductVariations(siteID: siteID, productID: productID, productVariations: productVariations, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension ProductVariationStore {

    /// Synchronizes all the product reviews associated with a given Site ID (if any!).
    ///
    func synchronizeAllProductVariations(siteID: Int64, productID: Int64, onCompletion: @escaping (Result<[ProductVariation], Error>) -> Void) {
        let maxPageSize = 100 // API only allows to fetch a max of 100 variations at a time
        recursivelySyncAllVariations(siteID: siteID,
                                     productID: productID,
                                     pageNumber: Default.firstPageNumber,
                                     pageSize: maxPageSize) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                let storedVariations = self.storageManager.viewStorage.loadProductVariations(siteID: siteID, productID: productID) ?? []
                let readOnlyVariations = storedVariations.map { $0.toReadOnly() }
                onCompletion(.success(readOnlyVariations))
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Synchronizes the product reviews associated with a given Site ID (if any!).
    /// If successful, the result boolean value, will indicate weather there are more variations to fetch or not.
    ///
    func synchronizeProductVariations(siteID: Int64, productID: Int64, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        remote.loadAllProductVariations(for: siteID,
                                        productID: productID,
                                        context: nil,
                                        pageNumber: pageNumber,
                                        pageSize: pageSize) { [weak self] (productVariations, error) in
            guard let productVariations = productVariations else {
                onCompletion(.failure(error ?? NSError()))
                return
            }

            if pageNumber == Default.firstPageNumber {
                self?.deleteStoredProductVariations(siteID: siteID,
                                                    productID: productID)
            }

            self?.upsertStoredProductVariationsInBackground(readOnlyProductVariations: productVariations,
                                                            siteID: siteID,
                                                            productID: productID) {
                let couldBeMoreVariationsToFetch = productVariations.count == pageSize
                onCompletion(.success(couldBeMoreVariationsToFetch))
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

    /// Bulk creates the provided array of product variations.
    /// Returns all product variations on it's completion block.
    ///
    func createProductVariations(siteID: Int64,
                                 productID: Int64,
                                 productVariations: [CreateProductVariation],
                                 onCompletion: @escaping (Result<[ProductVariation], Error>) -> Void) {
        remote.createProductVariations(siteID: siteID,
                                       productID: productID,
                                       productVariations: productVariations) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let productVariations):
                self.upsertStoredProductVariationsInBackground(readOnlyProductVariations: productVariations,
                                                               siteID: siteID,
                                                               productID: productID) { [weak self] in
                    guard let storageProductVariation = self?.storageManager.viewStorage.loadProductVariations(siteID: siteID, productID: productID) else {
                        return onCompletion(.failure(ProductVariationLoadError.notFoundInStorage))

                    }
                    onCompletion(.success(storageProductVariation.map { $0.toReadOnly() }))
                }
            case .failure(let error):
                onCompletion(.failure(error))
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

    func updateProductVariationImage(siteID: Int64,
                                     productID: Int64,
                                     variationID: Int64,
                                     image: ProductImage,
                                     completion: @escaping (Result<ProductVariation, ProductUpdateError>) -> Void) {
        remote.updateProductVariationImage(siteID: siteID,
                                           productID: productID,
                                           variationID: variationID,
                                           image: image) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .failure(let error):
                completion(.failure(ProductUpdateError(error: error)))
            case .success(let productVariation):
                self.upsertStoredProductVariationsInBackground(readOnlyProductVariations: [productVariation],
                                                               siteID: productVariation.siteID,
                                                               productID: productVariation.productID) { [weak self] in
                    guard let storageProductVariation = self?.storageManager.viewStorage
                        .loadProductVariation(siteID: productVariation.siteID,
                                              productVariationID: productVariation.productVariationID) else {
                        return completion(.failure(.notFoundInStorage))
                    }
                    completion(.success(storageProductVariation.toReadOnly()))
                }
            }
        }
    }

    /// Bulk updates the procvided array of product variations.
    ///
    func updateProductVariations(siteID: Int64,
                                 productID: Int64,
                                 productVariations: [ProductVariation],
                                 onCompletion: @escaping (Result<[ProductVariation], ProductUpdateError>) -> Void) {
        remote.updateProductVariations(siteID: siteID,
                                       productID: productID,
                                       productVariations: productVariations) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                onCompletion(.failure(ProductUpdateError(error: error)))
            case .success(let productVariations):
                self.upsertStoredProductVariationsInBackground(readOnlyProductVariations: productVariations,
                                                               siteID: siteID,
                                                               productID: productID) { [weak self] in
                                                                guard let storageProductVariation = self?.storageManager.viewStorage
                                                                    .loadProductVariations(siteID: siteID,
                                                                                           productID: productID) else {
                                                                                            onCompletion(.failure(.notFoundInStorage))
                                                                                            return
                                                                }
                    onCompletion(.success(storageProductVariation.map { $0.toReadOnly() }))
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

    /// Deletes the product variation.
    ///
    func deleteProductVariation(productVariation: ProductVariation, onCompletion: @escaping (Result<Void, ProductUpdateError>) -> Void) {
        remote.deleteProductVariation(siteID: productVariation.siteID,
                                      productID: productVariation.productID,
                                      variationID: productVariation.productVariationID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let productVariation):
                self.deleteStoredProductVariation(siteID: productVariation.siteID, productVariationID: productVariation.productVariationID)
                onCompletion(.success(()))
            case .failure(let error):
                onCompletion(.failure(ProductUpdateError(error: error)))
            }
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

    /// Deletes any Storage.ProductVariation with the specified `siteID` and `productID`
    ///
    func deleteStoredProductVariation(siteID: Int64, productVariationID: Int64) {
        let storage = storageManager.viewStorage
        storage.deleteProductVariation(siteID: siteID, productVariationID: productVariationID)
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
            handleProductSubscription(readOnlyProductVariation, storageProductVariation, storage)
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

    /// Recursively sync all product variations starting with the given page number and using a maximum page size.
    ///
    private func recursivelySyncAllVariations(siteID: Int64,
                                              productID: Int64,
                                              pageNumber: Int,
                                              pageSize: Int,
                                              onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        synchronizeProductVariations(siteID: siteID, productID: productID, pageNumber: pageNumber, pageSize: pageSize) { [weak self] result in
            switch result {
            case .success(let hasMoreVariationsToFetch):
                guard hasMoreVariationsToFetch else {
                    return onCompletion(.success(false))
                }
                self?.recursivelySyncAllVariations(siteID: siteID,
                                                   productID: productID,
                                                   pageNumber: pageNumber + 1,
                                                   pageSize: pageSize,
                                                   onCompletion: onCompletion)
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }
}

public enum ProductVariationLoadError: Error, Equatable {
    case notFoundInStorage
    case unexpected
    case requestMissingVariations
}
