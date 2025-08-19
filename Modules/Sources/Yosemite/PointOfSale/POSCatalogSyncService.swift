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

    // `@MainActor` is mainly for printing `storageManager.viewStorage.countObjects` for now
    @MainActor
    public func syncCatalog() async throws {
        let totalStartTime = CFAbsoluteTimeGetCurrent()

        // 1. Download catalog
        let downloadStartTime = CFAbsoluteTimeGetCurrent()
        let data = try await downloadCatalog()
        let downloadTime = CFAbsoluteTimeGetCurrent() - downloadStartTime
        print("🟣 Download completed - Time: \(String(format: "%.2f", downloadTime))s")

        // 2. Parse catalog data
        let parseStartTime = CFAbsoluteTimeGetCurrent()
        let catalogResponse = try parseCatalogData(data)
        let parseTime = CFAbsoluteTimeGetCurrent() - parseStartTime
        print("🟣 Parsing completed - Time: \(String(format: "%.2f", parseTime))s")

        // 3. Upsert catalog items
        let upsertStartTime = CFAbsoluteTimeGetCurrent()
        try await upsertCatalogItems(from: catalogResponse)
        let upsertTime = CFAbsoluteTimeGetCurrent() - upsertStartTime
        print("🟣 Upsert completed - Time: \(String(format: "%.2f", upsertTime))s")

        // Total time
        let totalTime = CFAbsoluteTimeGetCurrent() - totalStartTime
        print("✅ Sync completed - Total: \(String(format: "%.2f", totalTime))s (Download: \(String(format: "%.2f", downloadTime))s, Parse: \(String(format: "%.2f", parseTime))s, Upsert: \(String(format: "%.2f", upsertTime))s)")
        print("📊 Final counts: \(storageManager.viewStorage.countObjects(ofType: StorageProduct.self)) products, \(storageManager.viewStorage.countObjects(ofType: StorageProductVariation.self)) variations")
    }

    // MARK: - Private Methods

    private func downloadCatalog() async throws -> Data {
        // Use background download for large catalog files following Apple's best practices
        var request = URLRequest(url: catalogURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        return try await network.backgroundDownload(for: request)
    }

    private func parseCatalogData(_ data: Data) throws -> CatalogItemResponse {
        do {
            let decoder = JSONDecoder()
            // Configure decoder for optimal performance with large datasets
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(CatalogItemResponse.self, from: data)
        } catch {
            throw error
        }
    }

    private func upsertCatalogItems(productItems: [CatalogItem], variationItems: [CatalogItem]) async throws {
        // Convert to Networking objects on background thread for better performance
        let (networkingProducts, networkingVariations) = await mapCatalogItemsToNetworkingObjects(
            productItems: productItems,
            variationItems: variationItems
        )

        // Use combined batch replacement for products and variations to ensure proper linking
        await replaceAllProductsAndVariations(products: networkingProducts, variations: networkingVariations)
    }

    private func mapCatalogItemsToNetworkingObjects(
        productItems: [CatalogItem],
        variationItems: [CatalogItem]
    ) async -> ([Product], [ProductVariation]) {
        async let products = productItems.compactMap { catalogItem -> Product? in
            mapCatalogItemToNetworkingProduct(catalogItem)
        }
        async let variations = variationItems.compactMap { catalogItem -> ProductVariation? in
            mapCatalogItemToNetworkingProductVariation(catalogItem)
        }
        return await (products, variations)
    }

    // For exported json where variations are not separate
    private func upsertCatalogItems(from catalogItems: [CatalogItem]) async throws {
        // Separate products and variations
        let productItems = catalogItems.filter { !$0.type.contains("variation") }
        let variationItems = catalogItems.filter { $0.type.contains("variation") }

        try await upsertCatalogItems(productItems: productItems, variationItems: variationItems)
    }

    private func mapCatalogItemToNetworkingProduct(_ catalogItem: CatalogItem) -> Product? {
        guard !catalogItem.type.contains("variation") else { return nil }

        let dateFormatter = ISO8601DateFormatter()

        // Parse dates from the API format
        let dateOnSaleStart = catalogItem.dateOnSaleFrom.flatMap { dateFormatter.date(from: $0) }
        let dateOnSaleEnd = catalogItem.dateOnSaleTo.flatMap { dateFormatter.date(from: $0) }

        // Parse stock quantity from string
        let stockQuantity = catalogItem.stock.flatMap { Decimal(string: $0) }

        // Determine product status from published field
        let statusKey = (catalogItem.published == 1) ? "publish" : "private"

        // Parse product type from array
        let productTypeKey = catalogItem.type.first ?? "simple"

        // Create dimensions from individual fields
        let dimensions = ProductDimensions(
            length: catalogItem.length ?? "",
            width: catalogItem.width ?? "",
            height: catalogItem.height ?? ""
        )

        return Product(
            siteID: siteID,
            productID: catalogItem.id,
            name: catalogItem.name ?? "",
            slug: "",
            permalink: "",
            date: Date(),
            dateCreated: Date(),
            dateModified: nil,
            dateOnSaleStart: dateOnSaleStart,
            dateOnSaleEnd: dateOnSaleEnd,
            productTypeKey: productTypeKey,
            statusKey: statusKey,
            featured: catalogItem.featured ?? false,
            catalogVisibilityKey: catalogItem.catalogVisibility ?? "visible",
            fullDescription: catalogItem.description ?? "",
            shortDescription: catalogItem.shortDescription ?? "",
            sku: catalogItem.sku ?? "",
            globalUniqueID: catalogItem.globalUniqueID ?? "",
            price: "",
            regularPrice: catalogItem.regularPrice?.description ?? "",
            salePrice: catalogItem.salePrice ?? "",
            onSale: !(catalogItem.salePrice?.isEmpty ?? true),
            purchasable: true,
            totalSales: 0,
            virtual: false,
            downloadable: false,
            downloads: [],
            downloadLimit: Int64(catalogItem.downloadLimit ?? -1),
            downloadExpiry: Int64(catalogItem.downloadExpiry ?? -1),
            buttonText: catalogItem.buttonText ?? "",
            externalURL: catalogItem.productURL ?? "",
            taxStatusKey: catalogItem.taxStatus ?? "taxable",
            taxClass: catalogItem.taxClass ?? "",
            manageStock: !(catalogItem.stock?.isEmpty ?? true),
            stockQuantity: stockQuantity,
            stockStatusKey: catalogItem.stockStatus ?? "instock",
            backordersKey: catalogItem.backorders ?? "no",
            backordersAllowed: catalogItem.backorders == "yes",
            backordered: false,
            soldIndividually: catalogItem.soldIndividually ?? false,
            weight: catalogItem.weight ?? "",
            dimensions: dimensions,
            shippingRequired: true,
            shippingTaxable: true,
            shippingClass: "",
            shippingClassID: 0,
            productShippingClass: nil,
            reviewsAllowed: catalogItem.reviewsAllowed ?? true,
            averageRating: "",
            ratingCount: 0,
            relatedIDs: [],
            upsellIDs: catalogItem.upsellIDs ?? [],
            crossSellIDs: catalogItem.crossSellIDs ?? [],
            parentID: catalogItem.parentID ?? 0,
            purchaseNote: catalogItem.purchaseNote ?? "",
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
        guard catalogItem.type.contains("variation") else { return nil }

        let dateFormatter = ISO8601DateFormatter()

        // Parse dates from the API format
        let dateOnSaleStart = catalogItem.dateOnSaleFrom.flatMap { dateFormatter.date(from: $0) }
        let dateOnSaleEnd = catalogItem.dateOnSaleTo.flatMap { dateFormatter.date(from: $0) }

        // Determine status from published field
        let status = ProductStatus(rawValue: (catalogItem.published == 1) ? "publish" : "private") ?? .published

        // Parse stock quantity from string
        let stockQuantity = catalogItem.stock.flatMap { Decimal(string: $0) }
        let stockStatus = ProductStockStatus(rawValue: catalogItem.stockStatus ?? ProductStockStatus.inStock.rawValue) ?? .inStock

        // Create dimensions from individual fields
        let dimensions = ProductDimensions(
            length: catalogItem.length ?? "",
            width: catalogItem.width ?? "",
            height: catalogItem.height ?? ""
        )

        // Convert attributes from the new format
        let attributes = catalogItem.attributes?.map { attr in
            ProductVariationAttribute(
                id: 0,
                name: attr.name,
                option: attr.value.joined(separator: ", ")
            )
        } ?? []

        // Parse first image URL if available
        let image = catalogItem.images?.first.flatMap { imageURL in
            ProductImage(
                imageID: 0,
                dateCreated: Date(),
                dateModified: nil,
                src: imageURL,
                name: "",
                alt: ""
            )
        }

        return ProductVariation(
            siteID: siteID,
            productID: catalogItem.parentID ?? 0,
            productVariationID: catalogItem.id,
            attributes: attributes,
            image: image,
            permalink: "",
            dateCreated: Date(),
            dateModified: nil,
            dateOnSaleStart: dateOnSaleStart,
            dateOnSaleEnd: dateOnSaleEnd,
            status: status,
            description: catalogItem.description ?? "",
            sku: catalogItem.sku ?? "",
            globalUniqueID: catalogItem.globalUniqueID ?? "",
            price: "",
            regularPrice: catalogItem.regularPrice?.description ?? "",
            salePrice: catalogItem.salePrice ?? "",
            onSale: !(catalogItem.salePrice?.isEmpty ?? true),
            purchasable: true,
            virtual: false,
            downloadable: false,
            downloads: [],
            downloadLimit: Int64(catalogItem.downloadLimit ?? -1),
            downloadExpiry: Int64(catalogItem.downloadExpiry ?? -1),
            taxStatusKey: catalogItem.taxStatus ?? "taxable",
            taxClass: catalogItem.taxClass ?? "",
            manageStock: !(catalogItem.stock?.isEmpty ?? true),
            stockQuantity: stockQuantity,
            stockStatus: stockStatus,
            backordersKey: catalogItem.backorders ?? "no",
            backordersAllowed: catalogItem.backorders == "yes",
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

private typealias CatalogItemResponse = [CatalogItem]

/// Represents a catalog item from the JSON response
///
private struct CatalogItem: Codable {
    let id: Int64
    let type: [String]
    let sku: String?
    let globalUniqueID: String?
    let name: String?
    let published: Int?
    let featured: Bool?
    let catalogVisibility: String?
    let shortDescription: String?
    let description: String?
    let dateOnSaleFrom: String?
    let dateOnSaleTo: String?
    let taxStatus: String?
    let taxClass: String?
    let stockStatus: String?
    let stock: String?
    let lowStockAmount: String?
    let backorders: String?
    let soldIndividually: Bool?
    let weight: String?
    let length: String?
    let width: String?
    let height: String?
    let reviewsAllowed: Bool?
    let purchaseNote: String?
    let salePrice: String?
    let regularPrice: Decimal?
    let categoryIDs: [String]?
    let tagIDs: [String]?
    let shippingClassID: [String]?
    let images: [String]?
    let downloadLimit: Int?
    let downloadExpiry: Int?
    let parentID: Int64?
    let groupedProducts: String?
    let upsellIDs: [Int64]?
    let crossSellIDs: [Int64]?
    let productURL: String?
    let buttonText: String?
    let menuOrder: Int?
    let attributes: [CatalogItemAttribute]?
    let brandIDs: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case sku
        case globalUniqueID = "global_unique_id"
        case name
        case published
        case featured
        case catalogVisibility = "catalog_visibility"
        case shortDescription = "short_description"
        case description
        case dateOnSaleFrom = "date_on_sale_from"
        case dateOnSaleTo = "date_on_sale_to"
        case taxStatus = "tax_status"
        case taxClass = "tax_class"
        case stockStatus = "stock_status"
        case stock
        case lowStockAmount = "low_stock_amount"
        case backorders
        case soldIndividually = "sold_individually"
        case weight
        case length
        case width
        case height
        case reviewsAllowed = "reviews_allowed"
        case purchaseNote = "purchase_note"
        case salePrice = "sale_price"
        case regularPrice = "regular_price"
        case categoryIDs = "category_ids"
        case tagIDs = "tag_ids"
        case shippingClassID = "shipping_class_id"
        case images
        case downloadLimit = "download_limit"
        case downloadExpiry = "download_expiry"
        case parentID = "parent_id"
        case groupedProducts = "grouped_products"
        case upsellIDs = "upsell_ids"
        case crossSellIDs = "cross_sell_ids"
        case productURL = "product_url"
        case buttonText = "button_text"
        case menuOrder = "menu_order"
        case attributes
        case brandIDs = "brand_ids"
    }
}

/// Represents product attributes from the catalog API response
private struct CatalogItemAttribute: Codable {
    let name: String
    let value: [String]
    let taxonomy: Bool
    let visible: Bool?
}
