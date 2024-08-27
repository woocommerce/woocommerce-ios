import Foundation
import Networking
import Storage

// MARK: - ProductStore
//
public class ProductStore: Store {
    private let remote: ProductsRemoteProtocol
    private let generativeContentRemote: GenerativeContentRemoteProtocol
    private let productVariationStorageManager: ProductVariationStorageManager

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    public override convenience init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        let remote = ProductsRemote(network: network)
        let generativeContentRemote = GenerativeContentRemote(network: network)
        self.init(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote, generativeContentRemote: generativeContentRemote)
    }

    public init(dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                network: Network,
                remote: ProductsRemoteProtocol,
                generativeContentRemote: GenerativeContentRemoteProtocol) {
        productVariationStorageManager = ProductVariationStorageManager(storageManager: storageManager)
        self.remote = remote
        self.generativeContentRemote = generativeContentRemote
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
        case .retrieveFirstPurchasableItemMatchFromSKU(siteID: let siteID, sku: let sku, onCompletion: let onCompletion):
            retrieveFirstPurchasableItemMatchFromSKU(siteID: siteID, sku: sku, onCompletion: onCompletion)
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
        case let .checkIfStoreHasProducts(siteID, status, onCompletion):
            checkIfStoreHasProducts(siteID: siteID, status: status, onCompletion: onCompletion)
        case let .identifyLanguage(siteID, string, feature, completion):
            identifyLanguage(siteID: siteID,
                             string: string, feature: feature,
                             completion: completion)
        case let .generateProductDescription(siteID, name, features, language, completion):
            generateProductDescription(siteID: siteID, name: name, features: features, language: language, completion: completion)
        case let .generateProductSharingMessage(siteID, url, name, description, language, completion):
            generateProductSharingMessage(siteID: siteID, url: url, name: name, description: description, language: language, completion: completion)
        case let .generateProductName(siteID, keywords, language, completion):
            generateProductName(siteID: siteID, keywords: keywords, language: language, completion: completion)
        case let .generateProductDetails(siteID, productName, scannedTexts, language, completion):
            generateProductDetails(siteID: siteID, productName: productName, scannedTexts: scannedTexts, language: language, completion: completion)
        case let .fetchNumberOfProducts(siteID, completion):
            fetchNumberOfProducts(siteID: siteID, completion: completion)
        case let .generateAIProduct(siteID,
                                    productName,
                                    keywords,
                                    language,
                                    tone,
                                    currencySymbol,
                                    dimensionUnit,
                                    weightUnit,
                                    categories,
                                    tags,
                                    completion):
            generateAIProduct(siteID: siteID,
                              productName: productName,
                              keywords: keywords,
                              language: language,
                              tone: tone,
                              currencySymbol: currencySymbol,
                              dimensionUnit: dimensionUnit,
                              weightUnit: weightUnit,
                              categories: categories,
                              tags: tags,
                              completion: completion)
        case let .fetchStockReport(siteID, stockType, pageNumber, pageSize, order, completion):
            fetchStockReport(siteID: siteID,
                             stockType: stockType,
                             pageNumber: pageNumber,
                             pageSize: pageSize,
                             order: order,
                             completion: completion)
        case let .fetchProductReports(siteID, productIDs, timeZone, earliestDateToInclude, latestDateToInclude, pageSize, pageNumber, orderBy, order, completion):
            fetchProductReports(siteID: siteID,
                                productIDs: productIDs,
                                timeZone: timeZone,
                                earliestDateToInclude: earliestDateToInclude,
                                latestDateToInclude: latestDateToInclude,
                                pageSize: pageSize,
                                pageNumber: pageNumber,
                                orderBy: orderBy,
                                order: order,
                                completion: completion)
        case let .fetchVariationReports(siteID,
                                        productIDs,
                                        variationIDs,
                                        timeZone,
                                        earliestDateToInclude,
                                        latestDateToInclude,
                                        pageSize,
                                        pageNumber,
                                        orderBy,
                                        order,
                                        completion):
            fetchVariationReports(siteID: siteID,
                                  productIDs: productIDs,
                                  variationIDs: variationIDs,
                                  timeZone: timeZone,
                                  earliestDateToInclude: earliestDateToInclude,
                                  latestDateToInclude: latestDateToInclude,
                                  pageSize: pageSize,
                                  pageNumber: pageNumber,
                                  orderBy: orderBy,
                                  order: order,
                                  completion: completion)
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
                        onCompletion: @escaping (Result<Bool, Error>) -> Void) {
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
                                          pageSize: pageSize,
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
                                          pageSize: pageSize,
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
                            pageSize: pageSize,
                            result: Result.success(results.prefix(pageSize).map { $0.toReadOnly() }),
                            onCompletion: { _ in onCompletion(!results.isEmpty) })
    }

    /// Synchronizes the products associated with a given Site ID, sorted by ascending name.
    ///
    func synchronizeProducts(siteID: Int64,
                             pageNumber: Int,
                             pageSize: Int = ProductsRemote.Default.pageSize,
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
                                    if let productType,
                                        let error = error as? DotcomError,
                                        case let .unknown(code, message) = error,
                                        code == "rest_invalid_param",
                                        message == "Invalid parameter(s): type",
                                        ProductType.coreTypes.contains(productType) == false {
                                        return onCompletion(.success(false))
                                    }
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

    /// Retrieves the first product associated with a given siteID and exact-matching SKU (if any)
    ///
    func retrieveFirstPurchasableItemMatchFromSKU(siteID: Int64, sku: String, onCompletion: @escaping (Result<SKUSearchResult, Error>) -> Void) {
        remote.searchProductsBySKU(for: siteID,
                                   keyword: sku,
                                   pageNumber: Remote.Default.firstPageNumber,
                                   pageSize: ProductsRemote.Default.pageSize,
                                   completion: { result in
            switch result {
            case let .success(products):
                let skuProducts = products.filter { $0.sku == sku }

                guard !skuProducts.isEmpty else {
                    return onCompletion(.failure(ProductLoadError.notFound))
                }

                guard let product = skuProducts.first(where: { $0.purchasable }) else {
                    return onCompletion(.failure(ProductLoadError.notPurchasable))
                }

                if let productVariation = product.toProductVariation() {
                    self.productVariationStorageManager.upsertStoredProductVariationsInBackground(readOnlyProductVariations: [productVariation],
                                                                                                  siteID: siteID,
                                                                                                  productID: productVariation.productID,
                                                                                                  onCompletion: {
                        onCompletion(.success(.variation(productVariation)))
                    })
                } else {
                    self.upsertStoredProductsInBackground(readOnlyProducts: [product], siteID: siteID, onCompletion: {
                        onCompletion(.success(.product(product)))
                    })
                }
            case let .failure(error):
                onCompletion(.failure(error))
            }
        })
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

    /// Checks if the store already has any products with the given status.
    /// Returns `false` if the store has no products.
    ///
    func checkIfStoreHasProducts(siteID: Int64, status: ProductStatus?, onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        // Check for locally stored products first.
        let storage = storageManager.viewStorage
        if let products = storage.loadProducts(siteID: siteID), !products.isEmpty {
            if let status, (products.filter { $0.statusKey == status.rawValue }.isEmpty) == false {
                return onCompletion(.success(true))
            } else if status == nil {
                return onCompletion(.success(true))
            }
        }

        // If there are no locally stored products, then check remote.
        remote.loadProductIDs(for: siteID, pageNumber: 1, pageSize: 1, productStatus: status) { result in
            switch result {
            case .success(let ids):
                onCompletion(.success(ids.isEmpty == false))
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    func identifyLanguage(siteID: Int64,
                          string: String,
                          feature: GenerativeContentRemoteFeature,
                          completion: @escaping (Result<String, Error>) -> Void) {
        Task { @MainActor in
            let result = await Result {
                try await generativeContentRemote.identifyLanguage(siteID: siteID,
                                                                   string: string,
                                                                   feature: feature)
            }
            completion(result)
        }
    }

    func generateProductDescription(siteID: Int64,
                                    name: String,
                                    features: String,
                                    language: String,
                                    completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = [
            "Write a description for a product with title ```\(name)``` and features: ```\(features)```.",
            "Your response should be in language \(language).",
            "Make the description 50-60 words or less.",
            "Use a 9th grade reading level.",
            "Perform in-depth keyword research relating to the product in the same language of the product title, " +
            "and use them in your sentences without listing them out."
        ].joined(separator: "\n")

        Task { @MainActor in
            let result = await Result {
                let description = try await generativeContentRemote.generateText(siteID: siteID, base: prompt, feature: .productDescription, responseFormat: .text)
                return description
            }
            completion(result)
        }
    }

    func generateProductSharingMessage(siteID: Int64,
                                       url: String,
                                       name: String,
                                       description: String,
                                       language: String,
                                       completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = [
            // swiftlint:disable:next line_length
            "Your task is to help a merchant create a message to share with their customers a product named ```\(name)```. More information about the product:",
            "- Product description: ```\(description)```",
            "- Product URL: \(url).",
            "Your response should be in language \(language).",
            "The length should be up to 3 sentences.",
            "Use a 9th grade reading level.",
            "Add related hashtags at the end of the message.",
            "Do not include the URL in the message.",
        ].joined(separator: "\n")

        Task { @MainActor in
            let result = await Result {
                let message = try await generativeContentRemote.generateText(siteID: siteID, base: prompt, feature: .productSharing, responseFormat: .text)
                    .trimmingCharacters(in: CharacterSet(["\""]))  // Trims quotation mark
                return message
            }
            completion(result)
        }
    }

    func generateProductDetails(siteID: Int64,
                                productName: String?,
                                scannedTexts: [String],
                                language: String,
                                completion: @escaping (Result<ProductDetailsFromScannedTexts, Error>) -> Void) {
        let keywords: [String] = {
            guard let productName else {
                return scannedTexts
            }
            return scannedTexts + [productName]
        }()
        let prompt = [
            "Write a name and description of a product for an online store given the keywords at the end.",
            "Return only a JSON dictionary with the name in `name` field, description in `description` field.",
            "The output should be in valid JSON format.",
            "The output should be in language \(language).",
            "Make the description 50-60 words or less.",
            "Use a 9th grade reading level.",
            "Perform in-depth keyword research relating to the product in the same language of the product title, " +
            "and use them in your sentences without listing them out." +
            "\(keywords)"
        ].joined(separator: "\n")
        Task { @MainActor in
            do {
                let jsonString = try await generativeContentRemote.generateText(siteID: siteID,
                                                                                base: prompt,
                                                                                feature: .productDetailsFromScannedTexts,
                                                                                responseFormat: .json)
                guard let jsonData = jsonString.data(using: .utf8) else {
                    return completion(.failure(DotcomError.resourceDoesNotExist))
                }
                let details = try JSONDecoder().decode(ProductDetailsFromScannedTexts.self, from: jsonData)
                completion(.success(.init(name: details.name, description: details.description)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func generateProductName(siteID: Int64,
                             keywords: String,
                             language: String,
                             completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = [
            "You are a WooCommerce SEO and marketing expert.",
            "Provide a product title to enhance the store's SEO performance and sales " +
            "based on the following product keywords: \(keywords).",
            "Your response should be in language \(language).",
            "Do not explain the suggestion, strictly return the product name only."
        ].joined(separator: "\n")

        Task { @MainActor in
            let result = await Result {
                let description = try await generativeContentRemote.generateText(siteID: siteID, base: prompt, feature: .productName, responseFormat: .text)
                return description
            }
            completion(result)
        }
    }

    func fetchNumberOfProducts(siteID: Int64, completion: @escaping (Result<Int64, Error>) -> Void) {
        Task { @MainActor in
            do {
                let numberOfProducts = try await remote.loadNumberOfProducts(siteID: siteID)
                completion(.success(numberOfProducts))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func generateAIProduct(siteID: Int64,
                           productName: String,
                           keywords: String,
                           language: String,
                           tone: String,
                           currencySymbol: String,
                           dimensionUnit: String?,
                           weightUnit: String?,
                           categories: [ProductCategory],
                           tags: [ProductTag],
                           completion: @escaping (Result<AIProduct, Error>) -> Void) {
        Task { @MainActor in
            let result = await Result {
                let product = try await generativeContentRemote.generateAIProduct(siteID: siteID,
                                                                                  productName: productName,
                                                                                  keywords: keywords,
                                                                                  language: language,
                                                                                  tone: tone,
                                                                                  currencySymbol: currencySymbol,
                                                                                  dimensionUnit: dimensionUnit,
                                                                                  weightUnit: weightUnit,
                                                                                  categories: categories,
                                                                                  tags: tags)
                return product
            }
            completion(result)
        }
    }

    func fetchStockReport(siteID: Int64,
                          stockType: String,
                          pageNumber: Int,
                          pageSize: Int,
                          order: ProductsRemote.Order,
                          completion: @escaping (Result<[ProductStock], Error>) -> Void) {
        Task { @MainActor in
            do {
                let stock = try await remote.loadStock(for: siteID,
                                                       with: stockType,
                                                       pageNumber: pageNumber,
                                                       pageSize: pageSize,
                                                       order: order)
                completion(.success(stock))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchProductReports(siteID: Int64,
                             productIDs: [Int64],
                             timeZone: TimeZone,
                             earliestDateToInclude: Date,
                             latestDateToInclude: Date,
                             pageSize: Int,
                             pageNumber: Int,
                             orderBy: ProductsRemote.OrderKey,
                             order: ProductsRemote.Order,
                             completion: @escaping (Result<[ProductReport], Error>) -> Void) {
        Task { @MainActor in
            do {
                let reports = try await remote.loadProductReports(for: siteID,
                                                                  productIDs: productIDs,
                                                                  timeZone: timeZone,
                                                                  earliestDateToInclude: earliestDateToInclude,
                                                                  latestDateToInclude: latestDateToInclude,
                                                                  pageSize: pageSize,
                                                                  pageNumber: pageNumber,
                                                                  orderBy: orderBy,
                                                                  order: order)
                completion(.success(reports))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchVariationReports(siteID: Int64,
                               productIDs: [Int64],
                               variationIDs: [Int64],
                               timeZone: TimeZone,
                               earliestDateToInclude: Date,
                               latestDateToInclude: Date,
                               pageSize: Int,
                               pageNumber: Int,
                               orderBy: ProductsRemote.OrderKey,
                               order: ProductsRemote.Order,
                               completion: @escaping (Result<[ProductReport], Error>) -> Void) {
        Task { @MainActor in
            do {
                let reports = try await remote.loadVariationReports(for: siteID,
                                                                    productIDs: productIDs,
                                                                    variationIDs: variationIDs,
                                                                    timeZone: timeZone,
                                                                    earliestDateToInclude: earliestDateToInclude,
                                                                    latestDateToInclude: latestDateToInclude,
                                                                    pageSize: pageSize,
                                                                    pageNumber: pageNumber,
                                                                    orderBy: orderBy,
                                                                    order: order)
                completion(.success(reports))
            } catch {
                completion(.failure(error))
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

            // Removes all default variation attributes and adds new ones from the readonly version.
            if let defaultVariationAttributes = storageBundledItem.defaultVariationAttributes {
                storageBundledItem.removeFromDefaultVariationAttributes(defaultVariationAttributes)
            }

            let storageDefaultVariationAttributes = readOnlyBundleItem.defaultVariationAttributes.map {
                let storageVariationAttribute = storage.insertNewObject(ofType: Storage.GenericAttribute.self)
                storageVariationAttribute.update(with: $0)
                return storageVariationAttribute
            }
            storageBundledItem.addToDefaultVariationAttributes(NSOrderedSet(array: storageDefaultVariationAttributes))

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
                             pageSize: Int,
                             result: Result<[Product], Error>,
                             onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        switch result {
        case .success(let products):
            upsertSearchResultsInBackground(siteID: siteID,
                                            keyword: keyword,
                                            filter: filter,
                                            readOnlyProducts: products) {
                let hasNextPage = products.count == pageSize
                onCompletion(.success(hasNextPage))
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
    case generic(message: String)

    init(error: Error) {
        guard let dotcomError = error as? DotcomError else {
            self = .unknown(error: error.toAnyError)
            return
        }
        switch dotcomError {
        case let .unknown(code, message):
            guard let errorCode = ErrorCode(rawValue: code) else {
                self = .unknown(error: dotcomError.toAnyError)
                return
            }
            self = errorCode.error(with: message)
        default:
            self = .unknown(error: dotcomError.toAnyError)
        }
    }

    private enum ErrorCode: String {
        case invalidSKU = "product_invalid_sku"
        case variationInvalidImageId = "woocommerce_variation_invalid_image_id"
        case invalidMaxQuantity = "woocommerce_rest_invalid_max_quantity"
        case invalidMinQuantity = "woocommerce_rest_invalid_min_quantity"
        case invalidVariationMaxQuantity = "woocommerce_rest_invalid_variation_max_quantity"
        case invalidVariationMinQuantity = "woocommerce_rest_invalid_variation_min_quantity"

        func error(with message: String?) -> ProductUpdateError {
            switch self {
            case .invalidSKU:
                return .invalidSKU
            case .variationInvalidImageId:
                return .variationInvalidImageId
            case .invalidMaxQuantity, .invalidMinQuantity, .invalidVariationMaxQuantity, .invalidVariationMinQuantity:
                return .generic(message: message ?? "")
            }
        }
    }
}

public enum ProductLoadError: Error, Equatable {
    case notFound
    case notFoundInStorage
    case notPurchasable
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

/// Product details that can be generated by AI with a list of scanned texts from a product image.
public struct ProductDetailsFromScannedTexts: Equatable, Decodable {
    /// Product name.
    public let name: String
    /// Product description.
    public let description: String

    public init(name: String, description: String) {
        self.name = name
        self.description = description
    }
}

private extension ProductType {
    static let coreTypes: Set<ProductType> = [.simple, .variable, .grouped, .affiliate]
}
