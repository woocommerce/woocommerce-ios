import Foundation
import Networking
import Storage

// MARK: - ProductStore
//
public class ProductStore: Store {
    private let remote: ProductsRemoteProtocol

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    public override convenience init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        let remote = ProductsRemote(network: network)
        self.init(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
    }

    public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, remote: ProductsRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

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
        case .addProduct(let product, let onCompletion):
            addProduct(product: product, onCompletion: onCompletion)
        case .deleteProduct(let siteID, let productID, let onCompletion):
            deleteProduct(siteID: siteID, productID: productID, onCompletion: onCompletion)
        case .resetStoredProducts(let onCompletion):
            resetStoredProducts(onCompletion: onCompletion)
        case .retrieveProduct(let siteID, let productID, let onCompletion):
            retrieveProduct(siteID: siteID, productID: productID, onCompletion: onCompletion)
        case .retrieveProducts(let siteID, let productIDs, let pageNumber, let pageSize, let onCompletion):
            retrieveProducts(siteID: siteID, productIDs: productIDs, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        case .retrievePopularCachedProducts(let siteID, let onCompletion):
            retrievePopularCachedProducts(siteID: siteID, onCompletion: onCompletion)
        case .retrieveRecentlySoldCachedProducts(let siteID, let onCompletion):
            retrieveRecentlySoldCachedProducts(siteID: siteID, onCompletion: onCompletion)
        case let.searchProductsInCache(siteID, keyword, pageSize, onCompletion):
            searchInCache(siteID: siteID, keyword: keyword, pageSize: pageSize, onCompletion: onCompletion)
        case let .searchProducts(siteID,
                                 keyword,
                                 filter,
                                 pageNumber,
                                 pageSize,
                                 stockStatus,
                                 productStatus,
                                 productType,
                                 productCategory,
                                 excludedProductIDs,
                                 onCompletion):

            searchProducts(siteID: siteID,
                           keyword: keyword,
                           filter: filter,
                           pageNumber: pageNumber,
                           pageSize: pageSize,
                           stockStatus: stockStatus,
                           productStatus: productStatus,
                           productType: productType,
                           productCategory: productCategory,
                           excludedProductIDs: excludedProductIDs,
                           onCompletion: onCompletion)
        case .synchronizeProducts(let siteID,
                                  let pageNumber,
                                  let pageSize,
                                  let stockStatus,
                                  let productStatus,
                                  let productType,
                                  let productCategory,
                                  let sortOrder,
                                  let excludedProductIDs,
                                  let shouldDeleteStoredProductsOnFirstPage,
                                  let onCompletion):
            synchronizeProducts(siteID: siteID,
                                pageNumber: pageNumber,
                                pageSize: pageSize,
                                stockStatus: stockStatus,
                                productStatus: productStatus,
                                productType: productType,
                                productCategory: productCategory,
                                sortOrder: sortOrder,
                                excludedProductIDs: excludedProductIDs,
                                shouldDeleteStoredProductsOnFirstPage: shouldDeleteStoredProductsOnFirstPage,
                                onCompletion: onCompletion)
        case .requestMissingProducts(let order, let onCompletion):
            requestMissingProducts(for: order, onCompletion: onCompletion)
        case .updateProduct(let product, let onCompletion):
            updateProduct(product: product, onCompletion: onCompletion)
        case .updateProductImages(let siteID, let productID, let images, let onCompletion):
            updateProductImages(siteID: siteID, productID: productID, images: images, onCompletion: onCompletion)
        case .updateProducts(let siteID, let products, let onCompletion):
            updateProducts(siteID: siteID, products: products, onCompletion: onCompletion)
        case .validateProductSKU(let sku, let siteID, let onCompletion):
            validateProductSKU(sku, siteID: siteID, onCompletion: onCompletion)
        case let .replaceProductLocally(product, onCompletion):
            replaceProductLocally(product: product, onCompletion: onCompletion)
        case let .checkProductsOnboardingEligibility(siteID: siteID, onCompletion: onCompletion):
            checkProductsOnboardingEligibility(siteID: siteID, onCompletion: onCompletion)
        case let .createTemplateProduct(siteID, template, onCompletion):
            createTemplateProduct(siteID: siteID, template: template, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension ProductStore {

    /// Deletes all of the Stored Products.
    ///
    func resetStoredProducts(onCompletion: () -> Void) {
        let storage = storageManager.viewStorage
        storage.deleteAllObjects(ofType: Storage.Product.self)
        storage.saveIfNeeded()
        DDLogDebug("Products deleted")

        onCompletion()
    }

    /// Searches all of the products that contain a given Keyword.
    ///
    func searchProducts(siteID: Int64,
                        keyword: String,
                        filter: ProductSearchFilter,
                        pageNumber: Int,
                        pageSize: Int,
                        stockStatus: ProductStockStatus?,
                        productStatus: ProductStatus?,
                        productType: ProductType?,
                        productCategory: ProductCategory?,
                        excludedProductIDs: [Int64],
                        onCompletion: @escaping (Result<Void, Error>) -> Void) {
        switch filter {
        case .all:
            remote.searchProducts(for: siteID,
                                  keyword: keyword,
                                  pageNumber: pageNumber,
                                  pageSize: pageSize,
                                  stockStatus: stockStatus,
                                  productStatus: productStatus,
                                  productType: productType,
                                  productCategory: productCategory,
                                  excludedProductIDs: excludedProductIDs) { [weak self] result in
                self?.handleSearchResults(siteID: siteID,
                                          keyword: keyword,
                                          filter: filter,
                                          result: result,
                                          onCompletion: onCompletion)
            }
        case .sku:
            remote.searchProductsBySKU(for: siteID,
                                       keyword: keyword,
                                       pageNumber: pageNumber,
                                       pageSize: pageSize) { [weak self] result in
                self?.handleSearchResults(siteID: siteID,
                                          keyword: keyword,
                                          filter: filter,
                                          result: result,
                                          onCompletion: onCompletion)
            }
        }
    }

    func searchInCache(siteID: Int64, keyword: String, pageSize: Int, onCompletion: @escaping (Bool) -> Void) {
        let namePredicate = NSPredicate(format: "name LIKE[c] %@", keyword)
        let sitePredicate = NSPredicate(format: "siteID == %lld", siteID)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [namePredicate, sitePredicate])

        let results = sharedDerivedStorage.allObjects(ofType: StorageProduct.self,
                                                      matching: predicate,
                                                      sortedBy: nil)

        handleSearchResults(siteID: siteID,
                            keyword: keyword,
                            filter: .all,
                            result: Result.success(results.prefix(pageSize).map { $0.toReadOnly() }),
                            onCompletion: { _ in onCompletion(!results.isEmpty) })
    }

    /// Synchronizes the products associated with a given Site ID, sorted by ascending name.
    ///
    func synchronizeProducts(siteID: Int64,
                             pageNumber: Int,
                             pageSize: Int,
                             stockStatus: ProductStockStatus?,
                             productStatus: ProductStatus?,
                             productType: ProductType?,
                             productCategory: ProductCategory?,
                             sortOrder: ProductsSortOrder,
                             excludedProductIDs: [Int64],
                             shouldDeleteStoredProductsOnFirstPage: Bool,
                             onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        remote.loadAllProducts(for: siteID,
                               context: nil,
                               pageNumber: pageNumber,
                               pageSize: pageSize,
                               stockStatus: stockStatus,
                               productStatus: productStatus,
                               productType: productType,
                               productCategory: productCategory,
                               orderBy: sortOrder.remoteOrderKey,
                               order: sortOrder.remoteOrder,
                               excludedProductIDs: excludedProductIDs) { [weak self] result in
                                switch result {
                                case .failure(let error):
                                    onCompletion(.failure(error))
                                case .success(let products):
                                    guard let self = self else {
                                        return
                                    }
                                    let shouldDeleteExistingProducts = pageNumber == Default.firstPageNumber && shouldDeleteStoredProductsOnFirstPage
                                    self.upsertStoredProductsInBackground(readOnlyProducts: products,
                                                                          siteID: siteID,
                                                                          shouldDeleteExistingProducts: shouldDeleteExistingProducts) {
                                        let hasNextPage = products.count == pageSize
                                        onCompletion(.success(hasNextPage))
                                    }
                                }
        }
    }

    /// Synchronizes the Products found in a specified Order.
    ///
    func requestMissingProducts(for order: Order, onCompletion: @escaping (Error?) -> Void) {
        let itemIDs = order.items.map { $0.productID }
        let productIDs = itemIDs.uniqued()  // removes duplicate product IDs

        let storage = storageManager.viewStorage
        var missingIDs = [Int64]()
        for productID in productIDs {
            let storageProduct = storage.loadProduct(siteID: order.siteID, productID: productID)
            if storageProduct == nil {
                missingIDs.append(productID)
            }
        }

        // Do not trigger API request for empty array of items
        guard !missingIDs.isEmpty else {
            onCompletion(nil)
            return
        }

        remote.loadProducts(for: order.siteID, by: missingIDs) { [weak self] result in
            switch result {
            case .success(let products):
                self?.upsertStoredProductsInBackground(readOnlyProducts: products, siteID: order.siteID, onCompletion: {
                    onCompletion(nil)
                })
            case .failure(let error):
                onCompletion(error)
            }
        }
    }

    /// Retrieves multiple products with a given siteID + productIDs.
    /// - Note: This is NOT a wrapper for retrieving a single product.
    ///
    func retrieveProducts(siteID: Int64,
                          productIDs: [Int64],
                          pageNumber: Int,
                          pageSize: Int,
                          onCompletion: @escaping (Result<(products: [Product], hasNextPage: Bool), Error>) -> Void) {
        guard productIDs.isEmpty == false else {
            onCompletion(.success((products: [], hasNextPage: false)))
            return
        }

        remote.loadProducts(for: siteID, by: productIDs, pageNumber: pageNumber, pageSize: pageSize) { [weak self] result in
            switch result {
            case .success(let products):
                self?.upsertStoredProductsInBackground(readOnlyProducts: products, siteID: siteID, onCompletion: {
                    let hasNextPage = products.count == pageSize
                    onCompletion(.success((products: products, hasNextPage: hasNextPage)))
                })
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Retrieves the product associated with a given siteID + productID (if any!).
    ///
    func retrieveProduct(siteID: Int64, productID: Int64, onCompletion: @escaping (Result<Product, Error>) -> Void) {
        remote.loadProduct(for: siteID, productID: productID) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .failure(let originalError):
                let error = ProductLoadError(underlyingError: originalError)

                if case ProductLoadError.notFound = error {
                    self.deleteStoredProduct(siteID: siteID, productID: productID)
                }

                onCompletion(.failure(error))
            case .success(let product):
                self.upsertStoredProductsInBackground(readOnlyProducts: [product], siteID: siteID) { [weak self] in
                    guard let storageProduct = self?.storageManager.viewStorage.loadProduct(siteID: siteID, productID: productID) else {
                        return onCompletion(.failure(ProductLoadError.notFoundInStorage))
                    }
                    onCompletion(.success(storageProduct.toReadOnly()))
                }
            }

        }
    }

    func retrievePopularCachedProducts(siteID: Int64, onCompletion: @escaping ([Product]) -> Void) {
        // Get completed orders
        let completedStorageOrders = sharedDerivedStorage.allObjects(ofType: StorageOrder.self,
                                                      matching: completedOrdersPredicate(from: siteID),
                                                      sortedBy: nil)

        let completedOrders = completedStorageOrders.map { $0.toReadOnly() }

        // Get product ids sorted by occurence
        let completedOrdersItems = completedOrders.flatMap { $0.items }
        let productIDCountDictionary = completedOrdersItems.reduce(into: [:]) { counts, orderItem in counts[orderItem.productID, default: 0] += 1 }
        let sortedByOccurenceProductIDs = productIDCountDictionary
            .sorted { $0.value > $1.value }
            .map { $0.key }
            .uniqued()

        // Retrieve products from product ids and finish
        let products = retrieveProducts(from: sortedByOccurenceProductIDs)
        onCompletion(products)
    }

    func retrieveRecentlySoldCachedProducts(siteID: Int64, onCompletion: @escaping ([Product]) -> Void) {
        let completedStorageOrders = sharedDerivedStorage.allObjects(ofType: StorageOrder.self,
                                                      matching: completedOrdersPredicate(from: siteID),
                                                      sortedBy: [NSSortDescriptor(key: #keyPath(StorageOrder.datePaid), ascending: false)])

        let completedOrders = completedStorageOrders.map { $0.toReadOnly() }

        let productIDs = completedOrders
            .flatMap { $0.items }
            .map { $0.productID }
            .uniqued()

        let products = retrieveProducts(from: productIDs)
        onCompletion(products)
    }

    func completedOrdersPredicate(from siteID: Int64) -> NSPredicate {
        let completedOrderPredicate = NSPredicate(format: "statusKey ==[c] %@", OrderStatusEnum.completed.rawValue)
        let sitePredicate = NSPredicate(format: "siteID == %lld", siteID)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [completedOrderPredicate, sitePredicate])
    }

    func retrieveProducts(from productIDs: [Int64]) -> [Product] {
        productIDs
            .compactMap {
                let predicate = NSPredicate(format: "productID == %lld", $0)
                let product = sharedDerivedStorage.allObjects(ofType: StorageProduct.self,
                                                          matching: predicate,
                                                          sortedBy: nil).first
                return product
            }.map { $0.toReadOnly() }
    }

    /// Adds a product.
    ///
    func addProduct(product: Product, onCompletion: @escaping (Result<Product, ProductUpdateError>) -> Void) {
        remote.addProduct(product: product) { [weak self] result in
            switch result {
            case .failure(let error):
                onCompletion(.failure(ProductUpdateError(error: error)))
            case .success(let product):
                self?.upsertStoredProductsInBackground(readOnlyProducts: [product], siteID: product.siteID) { [weak self] in
                    guard let storageProduct = self?.storageManager.viewStorage.loadProduct(siteID: product.siteID, productID: product.productID) else {
                        onCompletion(.failure(.notFoundInStorage))
                        return
                    }
                    onCompletion(.success(storageProduct.toReadOnly()))
                }
            }
        }
    }

    /// Delete an existing product.
    ///
    func deleteProduct(siteID: Int64, productID: Int64, onCompletion: @escaping (Result<Product, ProductUpdateError>) -> Void) {
        remote.deleteProduct(for: siteID, productID: productID) { (result) in
            switch result {
            case .failure(let error):
                onCompletion(.failure(ProductUpdateError(error: error)))
            case .success(let product):
                self.deleteStoredProduct(siteID: siteID, productID: productID)
                onCompletion(.success(product))
            }
        }
    }

    /// Updates the product.
    ///
    func updateProduct(product: Product, onCompletion: @escaping (Result<Product, ProductUpdateError>) -> Void) {
        remote.updateProduct(product: product) { [weak self] result in
            switch result {
            case .failure(let error):
                onCompletion(.failure(ProductUpdateError(error: error)))
            case .success(let product):
                self?.upsertStoredProductsInBackground(readOnlyProducts: [product], siteID: product.siteID) { [weak self] in
                    guard let storageProduct = self?.storageManager.viewStorage.loadProduct(siteID: product.siteID, productID: product.productID) else {
                        onCompletion(.failure(.notFoundInStorage))
                        return
                    }
                    onCompletion(.success(storageProduct.toReadOnly()))
                }
            }
        }
    }

    func updateProductImages(siteID: Int64, productID: Int64, images: [ProductImage], onCompletion: @escaping (Result<Product, ProductUpdateError>) -> Void) {
        remote.updateProductImages(siteID: siteID, productID: productID, images: images) { [weak self] result in
            switch result {
            case .failure(let error):
                onCompletion(.failure(ProductUpdateError(error: error)))
            case .success(let product):
                self?.upsertStoredProductsInBackground(readOnlyProducts: [product], siteID: product.siteID) { [weak self] in
                    guard let storageProduct = self?.storageManager.viewStorage.loadProduct(siteID: product.siteID, productID: product.productID) else {
                        return onCompletion(.failure(.notFoundInStorage))
                    }
                    onCompletion(.success(storageProduct.toReadOnly()))
                }
            }
        }
    }

    func updateProducts(siteID: Int64, products: [Product], onCompletion: @escaping (Result<[Product], ProductUpdateError>) -> Void) {
        remote.updateProducts(siteID: siteID, products: products) { [weak self] result in
            switch result {
            case .failure(let error):
                onCompletion(.failure(ProductUpdateError(error: error)))
            case .success(let returnedProducts):
                self?.upsertStoredProductsInBackground(readOnlyProducts: returnedProducts, siteID: siteID) { [weak self] in
                    guard let storageProducts = self?.storageManager.viewStorage.loadProducts(siteID: siteID,
                                                                                              productsIDs: returnedProducts.map { $0.productID }) else {
                        onCompletion(.failure(.notFoundInStorage))
                        return
                    }
                    onCompletion(.success(storageProducts.map { $0.toReadOnly() }))
                }
            }
        }
    }

    /// Validates the Product SKU against other Products in storage.
    ///
    func validateProductSKU(_ sku: String?, siteID: Int64, onCompletion: @escaping (Bool) -> Void) {
        guard let sku = sku, sku.isEmpty == false else {
            // It is valid to not have a sku.
            onCompletion(true)
            return
        }

        remote.searchSku(for: siteID, sku: sku) { result in
            switch result {
            case .success(let checkResult):
                let isValid = checkResult != sku
                onCompletion(isValid)
            case .failure:
                onCompletion(true)
            }
        }
    }

    /// Upserts a product in our local storage
    ///
    func replaceProductLocally(product: Product, onCompletion: @escaping () -> Void) {
        upsertStoredProductsInBackground(readOnlyProducts: [product], siteID: product.siteID, onCompletion: onCompletion)
    }

    /// Checks if the store is eligible for products onboarding.
    /// Returns `true` if the store has no products.
    ///
    func checkProductsOnboardingEligibility(siteID: Int64, onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        // Check for locally stored products first.
        let storage = storageManager.viewStorage
        if let products = storage.loadProducts(siteID: siteID), !products.isEmpty {
            return onCompletion(.success(false))
        }

        // If there are no locally stored products, then check remote.
        remote.loadProductIDs(for: siteID, pageNumber: 1, pageSize: 1) { result in
            switch result {
            case .success(let ids):
                onCompletion(.success(ids.isEmpty))
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Creates a product using the provided template type.
    /// The created product is not stored locally.
    ///
    func createTemplateProduct(siteID: Int64, template: ProductsRemote.TemplateType, onCompletion: @escaping (Result<Product, Error>) -> Void) {
        remote.createTemplateProduct(for: siteID, template: template) { [remote] result in
            switch result {
            case .success(let productID):
                remote.loadProduct(for: siteID, productID: productID, completion: onCompletion)

            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }
}


// MARK: - Storage: Product
//
extension ProductStore {

    /// Deletes any Storage.Product with the specified `siteID` and `productID`
    ///
    func deleteStoredProduct(siteID: Int64, productID: Int64) {
        let storage = storageManager.viewStorage
        guard let product = storage.loadProduct(siteID: siteID, productID: productID) else {
            return
        }

        storage.deleteObject(product)
        storage.saveIfNeeded()
    }

    /// Updates (OR Inserts) the specified ReadOnly Product Entities *in a background thread*.
    /// Also deletes existing products if requested.
    /// `onCompletion` will be called on the main thread!
    ///
    func upsertStoredProductsInBackground(readOnlyProducts: [Networking.Product],
                                          siteID: Int64,
                                          shouldDeleteExistingProducts: Bool = false,
                                          onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            if shouldDeleteExistingProducts {
                derivedStorage.deleteProducts(siteID: siteID)
            }
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
            // The "importing" status is only used for product import placeholders and should not be stored.
            guard readOnlyProduct.productStatus != .importing else {
                continue
            }
            let storageProduct = storage.loadProduct(siteID: readOnlyProduct.siteID, productID: readOnlyProduct.productID) ??
                storage.insertNewObject(ofType: Storage.Product.self)

            storageProduct.update(with: readOnlyProduct)
            handleProductShippingClass(storageProduct: storageProduct, storage)
            handleProductDimensions(readOnlyProduct, storageProduct, storage)
            handleProductAttributes(readOnlyProduct, storageProduct, storage)
            handleProductDefaultAttributes(readOnlyProduct, storageProduct, storage)
            handleProductImages(readOnlyProduct, storageProduct, storage)
            handleProductCategories(readOnlyProduct, storageProduct, storage)
            handleProductTags(readOnlyProduct, storageProduct, storage)
            handleProductDownloadableFiles(readOnlyProduct, storageProduct, storage)
            handleProductAddOns(readOnlyProduct, storageProduct, storage)
            handleProductBundledItems(readOnlyProduct, storageProduct, storage)
            handleProductCompositeComponents(readOnlyProduct, storageProduct, storage)
            handleProductSubscription(readOnlyProduct, storageProduct, storage)
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

    /// Updates the provided StorageProduct's productShippingClass using the existing `ProductShippingClass` in storage, if any
    ///
    func handleProductShippingClass(storageProduct: Storage.Product, _ storage: StorageType) {
        if let existingStorageShippingClass = storage.loadProductShippingClass(siteID: storageProduct.siteID,
                                                                               remoteID: storageProduct.shippingClassID) {
            storageProduct.productShippingClass = existingStorageShippingClass
        } else {
            storageProduct.productShippingClass = nil
        }
    }

    /// Updates, inserts, or prunes the provided StorageProduct's attributes using the provided read-only Product's attributes
    ///
    func handleProductAttributes(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        let siteID = readOnlyProduct.siteID
        let productID = readOnlyProduct.productID

        // Upsert the attributes from the read-only product
        for readOnlyAttribute in readOnlyProduct.attributes {
            if let existingStorageAttribute = storage.loadProductAttribute(siteID: siteID,
                                                                           productID: productID,
                                                                           attributeID: readOnlyAttribute.attributeID,
                                                                           name: readOnlyAttribute.name) {
                existingStorageAttribute.update(with: readOnlyAttribute)
            } else {
                let newStorageAttribute = storage.insertNewObject(ofType: Storage.ProductAttribute.self)
                newStorageAttribute.update(with: readOnlyAttribute)
                storageProduct.addToAttributes(newStorageAttribute)
            }
        }

        // Now, remove any objects that exist in storageProduct.attributes but not in readOnlyProduct.attributes
        storageProduct.attributes?.forEach { storageAttribute in
            if readOnlyProduct.attributes.first(where: { $0.attributeID == storageAttribute.attributeID && $0.name == storageAttribute.name } ) == nil {
                storageProduct.removeFromAttributes(storageAttribute)
                storage.deleteObject(storageAttribute)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageProduct's default attributes using the provided read-only Product's default attributes
    ///
    func handleProductDefaultAttributes(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        let siteID = readOnlyProduct.siteID
        let productID = readOnlyProduct.productID

        // Upsert the default attributes from the read-only product
        for readOnlyDefaultAttribute in readOnlyProduct.defaultAttributes {
            if let existingStorageDefaultAttribute = storage.loadProductDefaultAttribute(siteID: siteID,
                                                                                         productID: productID,
                                                                                         defaultAttributeID: readOnlyDefaultAttribute.attributeID,
                                                                                         name: readOnlyDefaultAttribute.name ?? "") {
                existingStorageDefaultAttribute.update(with: readOnlyDefaultAttribute)
            } else {
                let newStorageDefaultAttribute = storage.insertNewObject(ofType: Storage.ProductDefaultAttribute.self)
                newStorageDefaultAttribute.update(with: readOnlyDefaultAttribute)
                storageProduct.addToDefaultAttributes(newStorageDefaultAttribute)
            }
        }

        // Now, remove any objects that exist in storageProduct.defaultAttributes but not in readOnlyProduct.defaultAttributes
        storageProduct.defaultAttributes?.forEach { storageDefaultAttribute in
            if readOnlyProduct.defaultAttributes.first(where: {
                $0.attributeID == storageDefaultAttribute.attributeID && $0.name == storageDefaultAttribute.name } ) == nil {
                    storageProduct.removeFromDefaultAttributes(storageDefaultAttribute)
                    storage.deleteObject(storageDefaultAttribute)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageProduct's images using the provided read-only Product's images
    ///
    func handleProductImages(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        // Removes all the images first.
        storageProduct.imagesArray.forEach { existingStorageImage in
            storage.deleteObject(existingStorageImage)
        }

        // Inserts the images from the read-only product variation.
        var storageImages = [StorageProductImage]()
        for readOnlyImage in readOnlyProduct.images {
            let newStorageImage = storage.insertNewObject(ofType: Storage.ProductImage.self)
            newStorageImage.update(with: readOnlyImage)
            storageImages.append(newStorageImage)
        }
        storageProduct.images = NSOrderedSet(array: storageImages)
    }

    /// Updates, inserts, or prunes the provided StorageProduct's categories using the provided read-only Product's categories
    ///
    func handleProductCategories(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        let siteID = readOnlyProduct.siteID

        // Remove previous linked categories
        storageProduct.categories?.removeAll()

        // Upsert the categories from the read-only product
        for readOnlyCategory in readOnlyProduct.categories {
            if let existingStorageCategory = storage.loadProductCategory(siteID: siteID, categoryID: readOnlyCategory.categoryID) {
                // ProductCategory response comes without a `parentID` so we update it with the `existingStorageCategory` one
                let completeReadOnlyCategory = readOnlyCategory.parentIDUpdated(parentID: existingStorageCategory.parentID)
                existingStorageCategory.update(with: completeReadOnlyCategory)
                storageProduct.addToCategories(existingStorageCategory)
            } else {
                let newStorageCategory = storage.insertNewObject(ofType: Storage.ProductCategory.self)
                newStorageCategory.update(with: readOnlyCategory)
                storageProduct.addToCategories(newStorageCategory)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageProduct's tags using the provided read-only Product's tags
    ///
    func handleProductTags(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {

        let siteID = readOnlyProduct.siteID

        // Removes all the tags first.
        for tag in storageProduct.tagsArray {
            storageProduct.removeFromTags(tag)
        }

        // Inserts the tags from the read-only product.
        var storageTags = [StorageProductTag]()
        for readOnlyTag in readOnlyProduct.tags {

            if let existingStorageTag = storage.loadProductTag(siteID: siteID, tagID: readOnlyTag.tagID) {
                existingStorageTag.update(with: readOnlyTag)
                storageTags.append(existingStorageTag)
            } else {
                let newStorageTag = storage.insertNewObject(ofType: Storage.ProductTag.self)
                newStorageTag.update(with: readOnlyTag)
                storageTags.append(newStorageTag)
            }
        }
        storageProduct.addToTags(NSOrderedSet(array: storageTags))
    }

    /// Replaces the `storageProduct.addOns` with the new `readOnlyProduct.addOns`
    ///
    func handleProductAddOns(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        // Remove all previous addOns, they will be deleted as they have the `cascade` delete rule
        if let addOns = storageProduct.addOns {
            storageProduct.removeFromAddOns(addOns)
        }

        // Create and add `storageAddOns` from `readOnlyProduct.addOns`
        let storageAddOns = readOnlyProduct.addOns.map { readOnlyAddOn -> StorageProductAddOn in
            let storageAddOn = storage.insertNewObject(ofType: StorageProductAddOn.self)
            storageAddOn.update(with: readOnlyAddOn)
            handleProductAddOnsOptions(readOnlyAddOn, storageAddOn, storage)
            return storageAddOn
        }
        storageProduct.addToAddOns(NSOrderedSet(array: storageAddOns))
    }

    /// Replaces the `storageProductAddOn.options` with the new `readOnlyProductAddOn.options`
    ///
    func handleProductAddOnsOptions(_ readOnlyProductAddOn: Networking.ProductAddOn, _ storageProductAddOn: Storage.ProductAddOn, _ storage: StorageType) {
        // Remove all previous options, they will be deleted as they have the `cascade` delete rule
        if let options = storageProductAddOn.options {
            storageProductAddOn.removeFromOptions(options)
        }

        // Create and add `storageAddOnsOptions` from `readOnlyProductAddOn.options`
        let storageAddOnsOptions = readOnlyProductAddOn.options.map { readOnlyAddOnOption -> StorageProductAddOnOption in
            let storageAddOnOption = storage.insertNewObject(ofType: StorageProductAddOnOption.self)
            storageAddOnOption.update(with: readOnlyAddOnOption)
            return storageAddOnOption
        }
        storageProductAddOn.addToOptions(NSOrderedSet(array: storageAddOnsOptions))
    }

    /// Replaces the `storageProduct.bundledItems` with the new `readOnlyProduct.bundledItems`
    ///
    func handleProductBundledItems(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        // Remove all previous bundledItems, they will be deleted as they have the `cascade` delete rule
        if let bundledItems = storageProduct.bundledItems {
            storageProduct.removeFromBundledItems(bundledItems)
        }

        // Create and add `storageBundledItems` from `readOnlyProduct.bundledItems`
        let storageBundledItems = readOnlyProduct.bundledItems.map { readOnlyBundleItem -> StorageProductBundleItem in
            let storageBundledItem = storage.insertNewObject(ofType: StorageProductBundleItem.self)
            storageBundledItem.update(with: readOnlyBundleItem)
            return storageBundledItem
        }
        storageProduct.addToBundledItems(NSOrderedSet(array: storageBundledItems))
    }

    /// Replaces the `storageProduct.compositeComponents` with the new `readOnlyProduct.compositeComponents`
    ///
    func handleProductCompositeComponents(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        // Remove all previous compositeComponents, they will be deleted as they have the `cascade` delete rule
        if let compositeComponents = storageProduct.compositeComponents {
            storageProduct.removeFromCompositeComponents(compositeComponents)
        }

        // Create and add `storageCompositeComponents` from `readOnlyProduct.compositeComponents`
        let storageCompositeComponents = readOnlyProduct.compositeComponents.map { readOnlyCompositeComponent -> StorageProductCompositeComponent in
            let storageCompositeComponent = storage.insertNewObject(ofType: StorageProductCompositeComponent.self)
            storageCompositeComponent.update(with: readOnlyCompositeComponent)
            return storageCompositeComponent
        }
        storageProduct.addToCompositeComponents(NSOrderedSet(array: storageCompositeComponents))
    }

    /// Updates, inserts, or prunes the provided StorageProduct's subscription using the provided read-only Product's subscription
    ///
    func handleProductSubscription(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        guard let readOnlySubscription = readOnlyProduct.subscription else {
            if let existingStorageSubscription = storageProduct.subscription {
                storage.deleteObject(existingStorageSubscription)
            }
            return
        }

        if let existingStorageSubscription = storageProduct.subscription {
            existingStorageSubscription.update(with: readOnlySubscription)
        } else {
            let newStorageSubscription = storage.insertNewObject(ofType: Storage.ProductSubscription.self)
            newStorageSubscription.update(with: readOnlySubscription)
            storageProduct.subscription = newStorageSubscription
        }
    }
}

// MARK: - Storage: Product Downloadable Files
//
private extension ProductStore {

    /// Updates, inserts, or prunes the provided StorageProduct's downloadable files using the provided read-only Product's downloadable files
    ///
    func handleProductDownloadableFiles(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {

        removeAllProductDownloadableFiles(storageProduct, storage)
        insertAllProductDownloadableFiles(readOnlyProduct, storageProduct, storage)
    }

    /// Removes the provided StorageProduct's all downloadable files from provided storage
    ///
    func removeAllProductDownloadableFiles(_ storageProduct: Storage.Product, _ storage: StorageType) {

        storageProduct.downloadableFilesArray.forEach { existingStorageDownloadableFile in
            storage.deleteObject(existingStorageDownloadableFile)
            storageProduct.removeFromDownloads(existingStorageDownloadableFile)
        }
    }

    /// Inserts the read-only Product's all downloadable files into provided StorageProduct's downloadable files using the storage
    ///
    func insertAllProductDownloadableFiles(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {

        let storageDownloadsSet = NSMutableOrderedSet()
        for readOnlyDownloadableFile in readOnlyProduct.downloads {

            let newStorageDownloadableFile = storage.insertNewObject(ofType: Storage.ProductDownload.self)
            newStorageDownloadableFile.update(with: readOnlyDownloadableFile)
            storageDownloadsSet.add(newStorageDownloadableFile)
        }
        storageProduct.addToDownloads(storageDownloadsSet)
    }
}

// MARK: - Storage: Search Results
//
private extension ProductStore {
    func handleSearchResults(siteID: Int64,
                             keyword: String,
                             filter: ProductSearchFilter,
                             result: Result<[Product], Error>,
                             onCompletion: @escaping (Result<Void, Error>) -> Void) {
        switch result {
        case .success(let products):
            upsertSearchResultsInBackground(siteID: siteID,
                                            keyword: keyword,
                                            filter: filter,
                                            readOnlyProducts: products) {
                onCompletion(.success(()))
            }
        case .failure(let error):
            onCompletion(.failure(error))
        }
    }

    /// Upserts the Products, and associates them to the SearchResults Entity (in Background)
    ///
    private func upsertSearchResultsInBackground(siteID: Int64,
                                                 keyword: String,
                                                 filter: ProductSearchFilter,
                                                 readOnlyProducts: [Networking.Product],
                                                 onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            self?.upsertStoredProducts(readOnlyProducts: readOnlyProducts, in: derivedStorage)
            self?.upsertStoredResults(siteID: siteID, keyword: keyword, filter: filter, readOnlyProducts: readOnlyProducts, in: derivedStorage)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Upserts the Products, and associates them to the Search Results Entity (in the specified Storage)
    ///
    private func upsertStoredResults(siteID: Int64,
                                     keyword: String,
                                     filter: ProductSearchFilter,
                                     readOnlyProducts: [Networking.Product],
                                     in storage: StorageType) {
        let searchResults = storage.loadProductSearchResults(keyword: keyword, filterKey: filter.rawValue) ??
        storage.insertNewObject(ofType: Storage.ProductSearchResults.self)
        searchResults.keyword = keyword
        searchResults.filterKey = filter.rawValue

        for readOnlyProduct in readOnlyProducts {
            guard let storedProduct = storage.loadProduct(siteID: siteID, productID: readOnlyProduct.productID) else {
                continue
            }

            searchResults.addToProducts(storedProduct)
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

/// An error that occurs while updating a Product.
///
/// - duplicatedSKU: the SKU is used by another Product.
/// - invalidSKU: the SKU is invalid or duplicated.
/// - passwordCannotBeUpdated: the password of a product cannot be updated.
/// - variationInvalidImageId: the body struct used for updating a product variation's image has an invalid id.
/// - unexpected: an error that is not expected to occur.
/// - unknown: other error cases.
///
public enum ProductUpdateError: Error, Equatable {
    case duplicatedSKU
    case invalidSKU
    case passwordCannotBeUpdated
    case notFoundInStorage
    case variationInvalidImageId
    case unexpected
    case unknown(error: AnyError)

    init(error: Error) {
        guard let dotcomError = error as? DotcomError else {
            self = .unknown(error: error.toAnyError)
            return
        }
        switch dotcomError {
        case .unknown(let code, _):
            guard let errorCode = ErrorCode(rawValue: code) else {
                self = .unknown(error: dotcomError.toAnyError)
                return
            }
            self = errorCode.error
        default:
            self = .unknown(error: dotcomError.toAnyError)
        }
    }

    private enum ErrorCode: String {
        case invalidSKU = "product_invalid_sku"
        case variationInvalidImageId = "woocommerce_variation_invalid_image_id"

        var error: ProductUpdateError {
            switch self {
            case .invalidSKU:
                return .invalidSKU
            case .variationInvalidImageId:
                return .variationInvalidImageId
            }
        }
    }
}

public enum ProductLoadError: Error, Equatable {
    case notFound
    case notFoundInStorage
    case unknown(error: AnyError)

    init(underlyingError error: Error) {
        guard case let DotcomError.unknown(code, _) = error else {
            self = .unknown(error: error.toAnyError)
            return
        }

        self = ErrorCode(rawValue: code)?.error ?? .unknown(error: error.toAnyError)
    }

    enum ErrorCode: String {
        case invalidID = "woocommerce_rest_product_invalid_id"

        var error: ProductLoadError {
            switch self {
            case .invalidID:
                return .notFound
            }
        }
    }
}
