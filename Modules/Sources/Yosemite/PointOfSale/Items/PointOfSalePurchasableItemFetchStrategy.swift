import Foundation
import protocol Networking.ProductsRemoteProtocol
import protocol Networking.ProductVariationsRemoteProtocol
import Storage
import CoreData

public protocol PointOfSalePurchasableItemFetchStrategy {
    func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct>
    func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation>
}

public struct PointOfSaleDefaultPurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    private let siteID: Int64

    private let productsRemote: ProductsRemoteProtocol
    private let variationsRemote: ProductVariationsRemoteProtocol
    private let analytics: POSItemFetchAnalyticsTracking

    static var defaultProductTypes: [ProductType] { [.simple, .variable] }

    init(siteID: Int64,
         productsRemote: ProductsRemoteProtocol,
         variationsRemote: ProductVariationsRemoteProtocol,
         analytics: POSItemFetchAnalyticsTracking) {
        self.siteID = siteID
        self.productsRemote = productsRemote
        self.variationsRemote = variationsRemote
        self.analytics = analytics
    }

    public func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        let pagedProducts = try await productsRemote.loadProductsForPointOfSale(
            for: siteID,
            productTypes: PointOfSaleDefaultPurchasableItemFetchStrategy.defaultProductTypes,
            pageNumber: pageNumber
        )

        if pageNumber == 1 {
            analytics.trackItemsFetchComplete(totalItems: pagedProducts.totalItems ?? 0)
        }

        return pagedProducts
    }

    public func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        try await variationsRemote
            .loadVariationsForPointOfSale(for: siteID,
                                          parentProductID: parentProductID,
                                          pageNumber: pageNumber)
    }
}

public struct PointOfSaleSearchPurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    private let siteID: Int64

    let searchTerm: String

    private let productsRemote: ProductsRemoteProtocol
    private let variationsRemote: ProductVariationsRemoteProtocol
    private let analytics: POSItemFetchAnalyticsTracking

    init(siteID: Int64,
         searchTerm: String,
         productsRemote: ProductsRemoteProtocol,
         variationsRemote: ProductVariationsRemoteProtocol,
         analytics: POSItemFetchAnalyticsTracking) {
        self.siteID = siteID
        self.searchTerm = searchTerm
        self.productsRemote = productsRemote
        self.variationsRemote = variationsRemote
        self.analytics = analytics
    }

    public func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        let startTime = Date()
        let pagedProducts = try await productsRemote.searchProductsForPointOfSale(
            for: siteID,
            query: searchTerm,
            productTypes: PointOfSaleDefaultPurchasableItemFetchStrategy.defaultProductTypes,
            pageNumber: pageNumber
        )
        if pageNumber == 1 {
            let milliseconds = Int(Date().timeIntervalSince(startTime) * Double(MSEC_PER_SEC))
            analytics.trackSearchRemoteResultsFetchComplete(millisecondsSinceRequestSent: milliseconds,
                                                            totalItems: pagedProducts.totalItems ?? 0)
        }
        return pagedProducts
    }

    public func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        try await variationsRemote
            .loadVariationsForPointOfSale(for: siteID,
                                          parentProductID: parentProductID,
                                          pageNumber: pageNumber)
    }
}

public struct PointOfSalePopularPurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    private let siteID: Int64
    private let productsRemote: ProductsRemoteProtocol
    private let variationsRemote: ProductVariationsRemoteProtocol
    private let pageSize: Int

    init(siteID: Int64,
         pageSize: Int,
         productsRemote: ProductsRemoteProtocol,
         variationsRemote: ProductVariationsRemoteProtocol) {
        self.siteID = siteID
        self.productsRemote = productsRemote
        self.variationsRemote = variationsRemote
        self.pageSize = pageSize
    }

    public func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        let receivedItems = try await productsRemote.loadPopularProductsForPointOfSale(
            for: siteID,
            productTypes: PointOfSaleDefaultPurchasableItemFetchStrategy.defaultProductTypes,
            pageNumber: pageNumber,
            perPage: pageSize
        )
        let modifiedItems = PagedItems<POSProduct>(items: receivedItems.items,
                                                   hasMorePages: false,
                                                   totalItems: receivedItems.totalItems)
        return modifiedItems
    }

    public func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        try await variationsRemote
            .loadVariationsForPointOfSale(for: siteID,
                                          parentProductID: parentProductID,
                                          pageNumber: pageNumber)
    }
}

public struct PointOfSaleLocalStoragePurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    private let siteID: Int64
    private let storageManager: StorageManagerType
    private let pageSize: Int

    static var defaultProductTypes: [ProductType] { [.simple, .variable] }

    public init(siteID: Int64,
         storageManager: StorageManagerType,
         pageSize: Int = 20) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.pageSize = pageSize
    }

    public func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        return try await MainActor.run {
            let storage = storageManager.viewStorage
            
            let predicate = NSPredicate(format: "siteID == %lld AND purchasable == YES AND (productTypeKey == %@ OR productTypeKey == %@)",
                                      siteID,
                                      ProductType.simple.rawValue,
                                      ProductType.variable.rawValue)
            
            // Get total count for pagination metadata
            let totalCount = storage.countObjects(ofType: StorageProduct.self, matching: predicate)
            
            // Create fetch request with true Core Data pagination
            let fetchRequest: NSFetchRequest<StorageProduct> = StorageProduct.fetchRequest()
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            fetchRequest.fetchLimit = pageSize
            fetchRequest.fetchOffset = (pageNumber - 1) * pageSize
            
            // Use StorageType's createFetchedResultsController with our paginated request
            let fetchedResultsController = storage.createFetchedResultsController(
                fetchRequest: fetchRequest,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            do {
                try fetchedResultsController.performFetch()
                let storageProducts = fetchedResultsController.fetchedObjects ?? []
                
                let hasMorePages = (pageNumber * pageSize) < totalCount
                
                let products = storageProducts.compactMap { storageProduct -> POSProduct? in
                    let product = storageProduct.toReadOnly()
                    return POSProduct(
                        siteID: product.siteID,
                        productID: product.productID,
                        name: product.name,
                        productTypeKey: product.productTypeKey,
                        sku: product.sku,
                        globalUniqueID: product.globalUniqueID,
                        price: product.price,
                        regularPrice: product.regularPrice,
                        salePrice: product.salePrice,
                        onSale: product.onSale,
                        downloadable: product.downloadable,
                        parentID: product.parentID,
                        images: product.images,
                        attributes: product.attributes,
                        manageStock: product.manageStock,
                        stockQuantity: product.stockQuantity,
                        stockStatusKey: product.stockStatusKey
                    )
                }
                
                return PagedItems<POSProduct>(
                    items: products,
                    hasMorePages: hasMorePages,
                    totalItems: totalCount
                )
            } catch {
                throw PointOfSaleItemServiceError.requestFailed
            }
        }
    }

    public func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        return try await MainActor.run {
            let storage = storageManager.viewStorage
            
            let predicate = NSPredicate(format: "siteID == %lld AND productID == %lld AND purchasable == YES",
                                      siteID,
                                      parentProductID)
            
            // Get total count for pagination metadata
            let totalCount = storage.countObjects(ofType: StorageProductVariation.self, matching: predicate)
            
            // Create fetch request with true Core Data pagination
            let fetchRequest: NSFetchRequest<StorageProductVariation> = StorageProductVariation.fetchRequest()
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "menuOrder", ascending: true)]
            fetchRequest.fetchLimit = pageSize
            fetchRequest.fetchOffset = (pageNumber - 1) * pageSize
            
            // Use StorageType's createFetchedResultsController with our paginated request
            let fetchedResultsController = storage.createFetchedResultsController(
                fetchRequest: fetchRequest,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            do {
                try fetchedResultsController.performFetch()
                let storageVariations = fetchedResultsController.fetchedObjects ?? []
                
                let hasMorePages = (pageNumber * pageSize) < totalCount
                
                let variations = storageVariations.compactMap { storageVariation -> POSProductVariation? in
                    let variation = storageVariation.toReadOnly()
                    return POSProductVariation(
                        siteID: variation.siteID,
                        productID: variation.productID,
                        productVariationID: variation.productVariationID,
                        attributes: variation.attributes,
                        image: variation.image,
                        sku: variation.sku,
                        globalUniqueID: variation.globalUniqueID,
                        price: variation.price,
                        regularPrice: variation.regularPrice,
                        salePrice: variation.salePrice,
                        onSale: variation.onSale,
                        downloadable: variation.downloadable,
                        manageStock: variation.manageStock,
                        stockQuantity: variation.stockQuantity,
                        stockStatusKey: variation.stockStatus.rawValue
                    )
                }
                
                return PagedItems<POSProductVariation>(
                    items: variations,
                    hasMorePages: hasMorePages,
                    totalItems: totalCount
                )
            } catch {
                throw PointOfSaleItemServiceError.requestFailed
            }
        }
    }
}

public struct PointOfSaleLocalStorageSearchStrategy: PointOfSalePurchasableItemFetchStrategy {
    private let siteID: Int64
    private let storageManager: StorageManagerType
    private let pageSize: Int
    private let searchTerm: String
    
    init(siteID: Int64,
         storageManager: StorageManagerType,
         searchTerm: String,
         pageSize: Int = 20) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.searchTerm = searchTerm
        self.pageSize = pageSize
    }
    
    public func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        return try await MainActor.run {
            let storage = storageManager.viewStorage
            
            // Create search predicate that includes the search term
            let basePredicate = NSPredicate(format: "siteID == %lld AND purchasable == YES AND (productTypeKey == %@ OR productTypeKey == %@)",
                                          siteID,
                                          ProductType.simple.rawValue,
                                          ProductType.variable.rawValue)
            
            let searchPredicate = NSPredicate(format: "name CONTAINS[cd] %@ OR sku CONTAINS[cd] %@", 
                                            searchTerm, searchTerm)
            
            let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, searchPredicate])
            
            // Get total count for pagination metadata
            let totalCount = storage.countObjects(ofType: StorageProduct.self, matching: combinedPredicate)
            
            // Create fetch request with true Core Data pagination
            let fetchRequest: NSFetchRequest<StorageProduct> = StorageProduct.fetchRequest()
            fetchRequest.predicate = combinedPredicate
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            fetchRequest.fetchLimit = pageSize
            fetchRequest.fetchOffset = (pageNumber - 1) * pageSize
            
            // Use StorageType's createFetchedResultsController with our paginated request
            let fetchedResultsController = storage.createFetchedResultsController(
                fetchRequest: fetchRequest,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            do {
                try fetchedResultsController.performFetch()
                let storageProducts = fetchedResultsController.fetchedObjects ?? []
                
                let hasMorePages = (pageNumber * pageSize) < totalCount
                
                let products = storageProducts.compactMap { storageProduct -> POSProduct? in
                    let product = storageProduct.toReadOnly()
                    return POSProduct(
                        siteID: product.siteID,
                        productID: product.productID,
                        name: product.name,
                        productTypeKey: product.productTypeKey,
                        sku: product.sku,
                        globalUniqueID: product.globalUniqueID,
                        price: product.price,
                        regularPrice: product.regularPrice,
                        salePrice: product.salePrice,
                        onSale: product.onSale,
                        downloadable: product.downloadable,
                        parentID: product.parentID,
                        images: product.images,
                        attributes: product.attributes,
                        manageStock: product.manageStock,
                        stockQuantity: product.stockQuantity,
                        stockStatusKey: product.stockStatusKey
                    )
                }
                
                return PagedItems<POSProduct>(
                    items: products,
                    hasMorePages: hasMorePages,
                    totalItems: totalCount
                )
            } catch {
                throw PointOfSaleItemServiceError.requestFailed
            }
        }
    }
    
    public func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        return try await MainActor.run {
            let storage = storageManager.viewStorage
            
            // Create search predicate for variations
            let basePredicate = NSPredicate(format: "siteID == %lld AND productID == %lld AND purchasable == YES",
                                          siteID,
                                          parentProductID)
            
            let searchPredicate = NSPredicate(format: "sku CONTAINS[cd] %@", searchTerm)
            let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, searchPredicate])
            
            // Get total count for pagination metadata
            let totalCount = storage.countObjects(ofType: StorageProductVariation.self, matching: combinedPredicate)
            
            // Create fetch request with true Core Data pagination
            let fetchRequest: NSFetchRequest<StorageProductVariation> = StorageProductVariation.fetchRequest()
            fetchRequest.predicate = combinedPredicate
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sku", ascending: true)]
            fetchRequest.fetchLimit = pageSize
            fetchRequest.fetchOffset = (pageNumber - 1) * pageSize
            
            // Use StorageType's createFetchedResultsController with our paginated request
            let fetchedResultsController = storage.createFetchedResultsController(
                fetchRequest: fetchRequest,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            do {
                try fetchedResultsController.performFetch()
                let storageVariations = fetchedResultsController.fetchedObjects ?? []
                
                let hasMorePages = (pageNumber * pageSize) < totalCount
                
                let variations = storageVariations.compactMap { storageVariation -> POSProductVariation? in
                    let variation = storageVariation.toReadOnly()
                    return POSProductVariation(
                        siteID: variation.siteID,
                        productID: variation.productID,
                        productVariationID: variation.productVariationID,
                        attributes: variation.attributes,
                        image: variation.image,
                        sku: variation.sku,
                        globalUniqueID: variation.globalUniqueID,
                        price: variation.price,
                        regularPrice: variation.regularPrice,
                        salePrice: variation.salePrice,
                        onSale: variation.onSale,
                        downloadable: variation.downloadable,
                        manageStock: variation.manageStock,
                        stockQuantity: variation.stockQuantity,
                        stockStatusKey: variation.stockStatus.rawValue
                    )
                }
                
                return PagedItems<POSProductVariation>(
                    items: variations,
                    hasMorePages: hasMorePages,
                    totalItems: totalCount
                )
            } catch {
                throw PointOfSaleItemServiceError.requestFailed
            }
        }
    }
}
