import Foundation
import Networking
import Storage
import CoreData

/// Manager for Point of Sale catalog synchronization
/// Downloads catalog data from remote source and persists to local storage
/// Handles large catalog files efficiently with streaming and batch processing
///
public final class POSCatalogSyncService: POSCatalogSyncServiceProtocol {

    // MARK: - Private Properties

    private let network: Network
    private let storageManager: StorageManagerType
    private let productStore: ProductStore
    private let productVariationStorageManager: ProductVariationStorageManager
    private let siteID: Int64
    private let catalogURL = URL(string: "REPLACE_WITH_ACTUAL_URL")!
    private let batchSize = 100 // Process items in batches to handle large datasets

    // MARK: - Initialization

    public init(siteID: Int64, network: Network, storageManager: StorageManagerType, dispatcher: Dispatcher) {
        self.siteID = siteID
        self.network = network
        self.storageManager = storageManager
        self.productStore = ProductStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        self.productVariationStorageManager = ProductVariationStorageManager(storageManager: storageManager)
    }

    // MARK: - POSCatalogSyncServiceProtocol

    public func syncCatalog() async throws {
        // Use background download for large catalog files following Apple's best practices
        var request = URLRequest(url: catalogURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let data = try await network.backgroundDownload(for: request)

        // Parse catalog data efficiently for large JSON files
        let catalogResponse = try parseCatalogDataEfficiently(data)
        try await upsertCatalogItems(productItems: catalogResponse.products, variationItems: catalogResponse.variations)
    }

    // MARK: - Private Methods

    private func parseCatalogDataEfficiently(_ data: Data) throws -> CatalogItemResponse {
        do {
            let decoder = JSONDecoder()
            // Configure decoder for optimal performance with large datasets
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(CatalogItemResponse.self, from: data)
        } catch {
            throw error
        }
    }

    @MainActor
    private func upsertCatalogItems(productItems: [CatalogItem], variationItems: [CatalogItem]) async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        // Convert to Networking objects
        let networkingProducts = productItems.compactMap { catalogItem -> Networking.Product? in
            return self.mapCatalogItemToNetworkingProduct(catalogItem)
        }

        let networkingVariations = variationItems.compactMap { catalogItem -> Networking.ProductVariation? in
            return self.mapCatalogItemToNetworkingProductVariation(catalogItem)
        }

        // Use combined batch replacement for products and variations to ensure proper linking
        await replaceAllProductsAndVariations(products: networkingProducts, variations: networkingVariations)

        let endTime = CFAbsoluteTimeGetCurrent()
        let timeElapsed = endTime - startTime
        print("✅ Done: \(storageManager.viewStorage.countObjects(ofType: StorageProduct.self)) products, \(storageManager.viewStorage.countObjects(ofType: StorageProductVariation.self)) variations - Time: \(String(format: "%.2f", timeElapsed))s")
    }

    // For exported json where variations are not separate
    private func upsertCatalogItems(from catalogItems: [CatalogItem]) async throws {
        // Separate products and variations
        let productItems = catalogItems.filter { $0.type != "variation" }
        let variationItems = catalogItems.filter { $0.type == "variation" }

        try await upsertCatalogItems(productItems: productItems, variationItems: variationItems)
    }

    private func mapCatalogItemToNetworkingProduct(_ catalogItem: CatalogItem) -> Product? {
        guard catalogItem.type != "variation" else { return nil }

        let dateFormatter = ISO8601DateFormatter()

        return Product(
            siteID: siteID,
            productID: catalogItem.id,
            name: catalogItem.name ?? "",
            slug: catalogItem.slug ?? "",
            permalink: catalogItem.permalink ?? "",
            date: Date(),
            dateCreated: catalogItem.dateCreated.flatMap { dateFormatter.date(from: $0) } ?? Date(),
            dateModified: catalogItem.dateModified.flatMap { dateFormatter.date(from: $0) },
            dateOnSaleStart: nil,
            dateOnSaleEnd: nil,
            productTypeKey: catalogItem.type,
            statusKey: catalogItem.status ?? "publish",
            featured: catalogItem.featured ?? false,
            catalogVisibilityKey: "visible",
            fullDescription: catalogItem.description ?? "",
            shortDescription: catalogItem.shortDescription ?? "",
            sku: catalogItem.sku ?? "",
            globalUniqueID: "",
            price: catalogItem.price ?? "",
            regularPrice: catalogItem.regularPrice ?? "",
            salePrice: catalogItem.salePrice ?? "",
            onSale: catalogItem.onSale ?? false,
            purchasable: catalogItem.purchasable ?? true,
            totalSales: 0,
            virtual: catalogItem.virtual ?? false,
            downloadable: catalogItem.downloadable ?? false,
            downloads: [],
            downloadLimit: -1,
            downloadExpiry: -1,
            buttonText: "",
            externalURL: "",
            taxStatusKey: "taxable",
            taxClass: "",
            manageStock: catalogItem.manageStock ?? false,
            stockQuantity: catalogItem.stockQuantity.map { Decimal($0) },
            stockStatusKey: catalogItem.stockStatus ?? "instock",
            backordersKey: "no",
            backordersAllowed: false,
            backordered: false,
            soldIndividually: false,
            weight: catalogItem.weight ?? "",
            dimensions: ProductDimensions(length: "", width: "", height: ""),
            shippingRequired: true,
            shippingTaxable: true,
            shippingClass: "",
            shippingClassID: 0,
            productShippingClass: nil,
            reviewsAllowed: true,
            averageRating: "",
            ratingCount: 0,
            relatedIDs: [],
            upsellIDs: [],
            crossSellIDs: [],
            parentID: 0,
            purchaseNote: "",
            categories: [],
            tags: [],
            images: [],
            attributes: [],
            defaultAttributes: [],
            variations: [],
            groupedProducts: [],
            menuOrder: catalogItem.menuOrder ?? 0,
            addOns: [],
            isSampleItem: false,
            bundleStockStatus: nil,
            bundleStockQuantity: nil,
            bundleMinSize: nil,
            bundleMaxSize: nil,
            bundledItems: [],
            password: nil,
            compositeComponents: [],
            subscription: nil,
            minAllowedQuantity: nil,
            maxAllowedQuantity: nil,
            groupOfQuantity: nil,
            combineVariationQuantities: nil,
            customFields: []
        )
    }

    private func mapCatalogItemToNetworkingProductVariation(_ catalogItem: CatalogItem) -> ProductVariation? {
        guard catalogItem.type == "variation" else { return nil }

        let dateFormatter = ISO8601DateFormatter()
        // Break up complex expressions
        let createdDate = catalogItem.dateCreated.flatMap { dateFormatter.date(from: $0) } ?? Date()
        let modifiedDate = catalogItem.dateModified.flatMap { dateFormatter.date(from: $0) }
        let status = ProductStatus(rawValue: catalogItem.status ?? ProductStatus.published.rawValue)
        let stockQuantity = catalogItem.stockQuantity.map { Decimal($0) }
        let stockStatus = ProductStockStatus(rawValue: catalogItem.stockStatus ?? ProductStockStatus.inStock.rawValue)
        let dimensions = ProductDimensions(length: "", width: "", height: "")

        return ProductVariation(
            siteID: siteID,
            productID: catalogItem.parentID ?? 0,
            productVariationID: catalogItem.id,
            attributes: [],
            image: nil,
            permalink: catalogItem.permalink ?? "",
            dateCreated: createdDate,
            dateModified: modifiedDate,
            dateOnSaleStart: nil,
            dateOnSaleEnd: nil,
            status: status,
            description: catalogItem.description ?? "",
            sku: catalogItem.sku ?? "",
            globalUniqueID: "",
            price: catalogItem.price ?? "",
            regularPrice: catalogItem.regularPrice ?? "",
            salePrice: catalogItem.salePrice ?? "",
            onSale: catalogItem.onSale ?? false,
            purchasable: catalogItem.purchasable ?? true,
            virtual: catalogItem.virtual ?? false,
            downloadable: catalogItem.downloadable ?? false,
            downloads: [],
            downloadLimit: -1,
            downloadExpiry: -1,
            taxStatusKey: "taxable",
            taxClass: "",
            manageStock: catalogItem.manageStock ?? false,
            stockQuantity: stockQuantity,
            stockStatus: stockStatus,
            backordersKey: "no",
            backordersAllowed: false,
            backordered: false,
            weight: catalogItem.weight,
            dimensions: dimensions,
            shippingClass: "",
            shippingClassID: 0,
            menuOrder: Int64(catalogItem.menuOrder ?? 0),
            subscription: nil,
            minAllowedQuantity: nil,
            maxAllowedQuantity: nil,
            groupOfQuantity: nil,
            overrideProductQuantities: nil
        )
    }

    private func mapError(_ error: Error) -> POSCatalogSyncError {
        if error is POSCatalogSyncError {
            return error as! POSCatalogSyncError
        }

        return POSCatalogSyncError.unknown
    }

    private func replaceAllProductsAndVariations(products: [Networking.Product], variations: [Networking.ProductVariation]) async {
        await storageManager.performAndSaveAsync({ [weak self] storage in
            guard let self else { return }

            let context = storage as! NSManagedObjectContext

            do {
                // 1. Delete existing products and variations
                // Products first (will cascade delete variations)
                let productFetchRequest: NSFetchRequest<NSFetchRequestResult> = Storage.Product.fetchRequest()
                productFetchRequest.predicate = NSPredicate(format: "siteID == %lld", siteID)
                let deleteProductRequest = NSBatchDeleteRequest(fetchRequest: productFetchRequest)
                deleteProductRequest.resultType = .resultTypeObjectIDs

                let deleteProductResult = try context.execute(deleteProductRequest) as? NSBatchDeleteResult
                let deletedProductIDs = deleteProductResult?.result as? [NSManagedObjectID] ?? []
                DDLogInfo("🟣 Batch delete returned \(deletedProductIDs.count) deleted product IDs")

                // Delete any remaining variations (in case they weren't cascade deleted)
                let variationFetchRequest: NSFetchRequest<NSFetchRequestResult> = Storage.ProductVariation.fetchRequest()
                variationFetchRequest.predicate = NSPredicate(format: "siteID == %lld", siteID)
                let deleteVariationRequest = NSBatchDeleteRequest(fetchRequest: variationFetchRequest)
                deleteVariationRequest.resultType = .resultTypeObjectIDs

                let deleteVariationResult = try context.execute(deleteVariationRequest) as? NSBatchDeleteResult
                let deletedVariationIDs = deleteVariationResult?.result as? [NSManagedObjectID] ?? []
                DDLogInfo("🟣 Deleted \(deletedVariationIDs.count) variations")

                // 3. Batch insert all products first
                guard !products.isEmpty else {
                    return
                }

                let productDictionaries = products.map { product in
                    self.convertProductToDataDictionary(product)
                }

                let batchInsert = NSBatchInsertRequest(entity: Storage.Product.entity(), objects: productDictionaries)
                batchInsert.resultType = .objectIDs

                let insertResult = try context.execute(batchInsert) as? NSBatchInsertResult
                let insertedProductIDs = insertResult?.result as? [NSManagedObjectID] ?? []
                DDLogInfo("🟣 Inserted \(insertedProductIDs.count) products")

                // 4. Create product ID mapping for variations
                var productIDToObjectID: [Int64: NSManagedObjectID] = [:]
                for (index, objectID) in insertedProductIDs.enumerated() {
                    if index < products.count {
                        let productID = products[index].productID
                        productIDToObjectID[productID] = objectID
                    }
                }

                // 5. Handle product related entities
                for (index, objectID) in insertedProductIDs.enumerated() {
                    if index < products.count,
                       let product = try? context.existingObject(with: objectID) as? Storage.Product {
                        self.handleProductRelatedEntities(products[index], product, storage)
                    }
                }

                // 6. Now batch insert variations with proper product relationships
                guard !variations.isEmpty else {
                    DDLogInfo("🟣 No variations to insert")
                    return
                }

                let variationDictionaries = variations.map { variation in
                    // NSBatchInsertRequest cannot handle relationships - they must be set after insertion
                    self.convertProductVariationToDataDictionary(variation)
                }

                let variationBatchInsert = NSBatchInsertRequest(entity: Storage.ProductVariation.entity(), objects: variationDictionaries)
                variationBatchInsert.resultType = .objectIDs

                let variationInsertResult = try context.execute(variationBatchInsert) as? NSBatchInsertResult
                let insertedVariationIDs = variationInsertResult?.result as? [NSManagedObjectID] ?? []
                DDLogInfo("🟣 Inserted \(insertedVariationIDs.count) variations")

                // 7. Set product relationships for variations (must be done after batch insert)
                for (index, objectID) in insertedVariationIDs.enumerated() {
                    if index < variations.count,
                       let variation = try? context.existingObject(with: objectID) as? Storage.ProductVariation {
                        let variationData = variations[index]

                        // Set the product relationship
                        if let productObjectID = productIDToObjectID[variationData.productID],
                           let product = try? context.existingObject(with: productObjectID) as? Storage.Product {
                            variation.product = product
                        }

                        self.handleProductVariationRelatedEntities(variationData, variation, storage)
                    }
                }
            } catch {
                print("⛔️ error replacing products and variations: \(error)")
                // Fallback to traditional approach
                self.fallbackReplaceProducts(products, in: storage)
                self.fallbackReplaceProductVariations(variations, in: storage)
            }
        }, on: .main)
    }

    private func fallbackReplaceProducts(_ products: [Networking.Product], in storage: StorageType) {
        // Delete all existing products for this siteID
        storage.deleteProducts(siteID: siteID)

        // Insert all new products
        for product in products {
            let storageProduct = storage.insertNewObject(ofType: Storage.Product.self)
            storageProduct.update(with: product)
            handleProductRelatedEntities(product, storageProduct, storage)
        }
    }

    private func fallbackReplaceProductVariations(_ variations: [Networking.ProductVariation], in storage: StorageType) {
        // Group variations by product ID and insert
        let variationsByProduct = Dictionary(grouping: variations) { $0.productID }

        for (productID, productVariations) in variationsByProduct {
            // Delete all existing variations for this siteID
            storage.deleteProductVariations(siteID: siteID, productID: productID)

            guard let product = storage.loadProduct(siteID: siteID, productID: productID) else {
                print("⛔️ No product found for ID \(productID), skipping variations")
                continue
            }

            for variation in productVariations {
                let storageVariation = storage.insertNewObject(ofType: Storage.ProductVariation.self)
                storageVariation.update(with: variation)
                storageVariation.product = product
                handleProductVariationRelatedEntities(variation, storageVariation, storage)
            }
        }
    }

    private func handleProductRelatedEntities(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
//        productStore.handleProductShippingClass(storageProduct: storageProduct, storage)
//        productStore.handleProductDimensions(readOnlyProduct, storageProduct, storage)
        productStore.handleProductAttributes(readOnlyProduct, storageProduct, storage)
        productStore.handleProductDefaultAttributes(readOnlyProduct, storageProduct, storage)
        productStore.handleProductImages(readOnlyProduct, storageProduct, storage)
//        productStore.handleProductCategories(readOnlyProduct, storageProduct, storage)
//        productStore.handleProductTags(readOnlyProduct, storageProduct, storage)
//        productStore.handleProductDownloadableFiles(readOnlyProduct, storageProduct, storage)
//        productStore.handleProductAddOns(readOnlyProduct, storageProduct, storage)
//        productStore.handleProductBundledItems(readOnlyProduct, storageProduct, storage)
//        productStore.handleProductCompositeComponents(readOnlyProduct, storageProduct, storage)
//        productStore.handleProductSubscription(readOnlyProduct, storageProduct, storage)
//        productStore.handleProductCustomFields(readOnlyProduct, storageProduct, storage)
    }

    private func handleProductVariationRelatedEntities(_ networkingVariation: Networking.ProductVariation, _ storageVariation: Storage.ProductVariation, _ storage: StorageType) {
        // TODO
    }

    private func convertProductToDataDictionary(_ product: Networking.Product) -> [String: Any] {
        [
            "siteID": product.siteID,
            "productID": product.productID,
            "name": product.name,
            "slug": product.slug,
            "permalink": product.permalink,
            "date": product.date,
            "dateCreated": product.dateCreated,
            "dateModified": product.dateModified as Any,
            "dateOnSaleStart": product.dateOnSaleStart as Any,
            "dateOnSaleEnd": product.dateOnSaleEnd as Any,
            "productTypeKey": product.productTypeKey,
            "statusKey": product.statusKey,
            "featured": product.featured,
            "catalogVisibilityKey": product.catalogVisibilityKey,
            "fullDescription": product.fullDescription ?? "",
            "briefDescription": product.shortDescription ?? "",
            "sku": product.sku,
            "globalUniqueID": product.globalUniqueID ?? "",
            "price": product.price,
            "regularPrice": product.regularPrice,
            "salePrice": product.salePrice,
            "onSale": product.onSale,
            "purchasable": product.purchasable,
            "totalSales": product.totalSales,
            "virtual": product.virtual,
            "downloadable": product.downloadable,
            "downloadLimit": product.downloadLimit,
            "downloadExpiry": product.downloadExpiry,
            "buttonText": product.buttonText,
            "externalURL": product.externalURL ?? "",
            "taxStatusKey": product.taxStatusKey,
            "taxClass": product.taxClass,
            "manageStock": product.manageStock,
            "stockQuantity": product.stockQuantity as Any,
            "stockStatusKey": product.stockStatusKey,
            "backordersKey": product.backordersKey,
            "backordersAllowed": product.backordersAllowed,
            "backordered": product.backordered,
            "soldIndividually": product.soldIndividually,
            "weight": product.weight,
            "shippingRequired": product.shippingRequired,
            "shippingTaxable": product.shippingTaxable,
            "shippingClass": product.shippingClass,
            "shippingClassID": product.shippingClassID,
            "reviewsAllowed": product.reviewsAllowed,
            "averageRating": product.averageRating,
            "ratingCount": product.ratingCount,
            "relatedIDs": product.relatedIDs,
            "upsellIDs": product.upsellIDs,
            "crossSellIDs": product.crossSellIDs,
            "parentID": product.parentID,
            "purchaseNote": product.purchaseNote,
            "menuOrder": product.menuOrder,
            "isSampleItem": product.isSampleItem,
            "bundleStockStatus": product.bundleStockStatus as Any,
            "bundleStockQuantity": product.bundleStockQuantity as Any,
            "bundleMinSize": product.bundleMinSize as Any,
            "bundleMaxSize": product.bundleMaxSize as Any,
            "password": product.password as Any,
            "minAllowedQuantity": product.minAllowedQuantity as Any,
            "maxAllowedQuantity": product.maxAllowedQuantity as Any,
            "groupOfQuantity": product.groupOfQuantity as Any,
            "combineVariationQuantities": product.combineVariationQuantities as Any,
            "groupedProducts": []
        ]
    }

    private func convertProductVariationToDataDictionary(_ variation: Networking.ProductVariation) -> [String: Any] {
        [
            "siteID": variation.siteID,
            "productID": variation.productID,
            "productVariationID": variation.productVariationID,
            "permalink": variation.permalink,
            "dateCreated": variation.dateCreated,
            "dateModified": variation.dateModified as Any,
            "dateOnSaleStart": variation.dateOnSaleStart as Any,
            "dateOnSaleEnd": variation.dateOnSaleEnd as Any,
            "statusKey": variation.status.rawValue,
            "fullDescription": variation.description,
            "sku": variation.sku,
            "globalUniqueID": variation.globalUniqueID ?? "",
            "price": variation.price,
            "regularPrice": variation.regularPrice,
            "salePrice": variation.salePrice,
            "onSale": variation.onSale,
            "purchasable": variation.purchasable,
            "virtual": variation.virtual,
            "downloadable": variation.downloadable,
            "downloadLimit": variation.downloadLimit,
            "downloadExpiry": variation.downloadExpiry,
            "taxStatusKey": variation.taxStatusKey,
            "taxClass": variation.taxClass,
            "manageStock": variation.manageStock,
            "stockQuantity": variation.stockQuantity as Any,
            "stockStatusKey": variation.stockStatus.rawValue,
            "backordersKey": variation.backordersKey,
            "backordersAllowed": variation.backordersAllowed,
            "backordered": variation.backordered,
            "weight": variation.weight,
            "shippingClass": variation.shippingClass,
            "shippingClassID": variation.shippingClassID,
            "menuOrder": variation.menuOrder,
            "minAllowedQuantity": variation.minAllowedQuantity as Any,
            "maxAllowedQuantity": variation.maxAllowedQuantity as Any,
            "groupOfQuantity": variation.groupOfQuantity as Any,
            "overrideProductQuantities": variation.overrideProductQuantities as Any
        ]
    }
}

// MARK: - Supporting Types

private struct CatalogItemResponse: Codable {
    let products: [CatalogItem]
    // Only in the poslarge JSON, not in exported JSON
    let variations: [CatalogItem]
}

/// Represents a catalog item from the JSON response
///
private struct CatalogItem: Codable {
    let id: Int64
    let name: String?
    let slug: String?
    let permalink: String?
    let type: String
    let status: String?
    let featured: Bool?
    let sku: String?
    let price: String?
    let regularPrice: String?
    let salePrice: String?
    let onSale: Bool?
    let purchasable: Bool?
    let virtual: Bool?
    let downloadable: Bool?
    let manageStock: Bool?
    let stockQuantity: Int?
    let stockStatus: String?
    let weight: String?
    let description: String?
    let shortDescription: String?
    let dateCreated: String?
    let dateModified: String?
    let menuOrder: Int?
    let parentID: Int64?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case slug
        case permalink
        case type
        case status
        case featured
        case sku
        case price
        case regularPrice = "regular_price"
        case salePrice = "sale_price"
        case onSale = "on_sale"
        case purchasable
        case virtual
        case downloadable
        case manageStock = "manage_stock"
        case stockQuantity = "stock_quantity"
        case stockStatus = "stock_status"
        case weight
        case description
        case shortDescription = "short_description"
        case dateCreated = "date_created"
        case dateModified = "date_modified"
        case menuOrder = "menu_order"
        // export version is "parent_id", but poslarge version is "post_parent"
        case parentID = "post_parent"
    }
}
