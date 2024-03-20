import Foundation
import Networking
import Storage

// MARK: - ProductVariationStore
//
public final class ProductVariationStore: Store {
    private let remote: ProductVariationsRemoteProtocol
    private let productVariationStorageManager: ProductVariationStorageManager

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    public override convenience init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        let remote = ProductVariationsRemote(network: network)
        self.init(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
    }

    init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, remote: ProductVariationsRemoteProtocol) {
        self.productVariationStorageManager = ProductVariationStorageManager(storageManager: storageManager)
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
        case .synchronizeProductVariationsSubset(let siteID, let productID, let variationIDs, let pageNumber, let pageSize, let onCompletion):
            synchronizeProductVariations(siteID: siteID,
                                         productID: productID,
                                         variationIDs: variationIDs,
                                         pageNumber: pageNumber,
                                         pageSize: pageSize,
                                         onCompletion: onCompletion)
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

    /// Synchronizes the product variations associated with a given Site ID, product ID, and an optional list of variation IDs.
    /// If successful, the result boolean value, will indicate weather there are more variations to fetch or not.
    ///
    func synchronizeProductVariations(siteID: Int64,
                                      productID: Int64,
                                      variationIDs: [Int64] = [],
                                      pageNumber: Int,
                                      pageSize: Int,
                                      onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        remote.loadAllProductVariations(for: siteID,
                                        productID: productID,
                                        variationIDs: variationIDs,
                                        context: nil,
                                        pageNumber: pageNumber,
                                        pageSize: pageSize) { [weak self] (productVariations, error) in
            guard let productVariations = productVariations else {
                onCompletion(.failure(error ?? ProductVariationLoadError.unexpected))
                return
            }

            if pageNumber == Default.firstPageNumber {
                self?.productVariationStorageManager.deleteStoredProductVariations(siteID: siteID,
                                                    productID: productID)
            }

            self?.productVariationStorageManager.upsertStoredProductVariationsInBackground(readOnlyProductVariations: productVariations,
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
                self.productVariationStorageManager.upsertStoredProductVariationsInBackground(readOnlyProductVariations: [productVariation],
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
                self.productVariationStorageManager.upsertStoredProductVariationsInBackground(readOnlyProductVariations: [productVariation],
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
                self.productVariationStorageManager.upsertStoredProductVariationsInBackground(readOnlyProductVariations: productVariations,
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
                self.productVariationStorageManager.upsertStoredProductVariationsInBackground(readOnlyProductVariations: [productVariation],
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
                self.productVariationStorageManager.upsertStoredProductVariationsInBackground(readOnlyProductVariations: [productVariation],
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
                self.productVariationStorageManager.upsertStoredProductVariationsInBackground(readOnlyProductVariations: productVariations,
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
                    self.productVariationStorageManager.upsertStoredProductVariationsInBackground(readOnlyProductVariations: [productVariation],
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
                self.productVariationStorageManager.deleteStoredProductVariation(siteID: productVariation.siteID,
                                                                                 productVariationID: productVariation.productVariationID)
                onCompletion(.success(()))
            case .failure(let error):
                onCompletion(.failure(ProductUpdateError(error: error)))
            }
        }
    }
}
private extension ProductVariationStore {
    /// Recursively sync all product variations starting with the given page number and using a maximum page size.
    ///
    private func recursivelySyncAllVariations(siteID: Int64,
                                              productID: Int64,
                                              pageNumber: Int,
                                              pageSize: Int,
                                              onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        synchronizeProductVariations(siteID: siteID, productID: productID, variationIDs: [], pageNumber: pageNumber, pageSize: pageSize) { [weak self] result in
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
