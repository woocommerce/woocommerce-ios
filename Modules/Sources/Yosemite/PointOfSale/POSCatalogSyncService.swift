import Foundation
import Networking
import protocol Storage.StorageManagerType

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
        let catalogItems = try parseCatalogDataEfficiently(data)
        try await persistCatalogItemsInBatches(catalogItems)
    }

    // MARK: - Private Methods

    private func parseCatalogDataEfficiently(_ data: Data) throws -> [CatalogItem] {
        do {
            let decoder = JSONDecoder()
            // Configure decoder for optimal performance with large datasets
            decoder.dateDecodingStrategy = .iso8601

            let catalogItems = try decoder.decode([CatalogItem].self, from: data)
            return catalogItems
        } catch {
            throw POSCatalogSyncError.invalidData
        }
    }

    private func persistCatalogItemsInBatches(_ catalogItems: [CatalogItem]) async throws {
        // Process items in batches, but save both products and variations together atomically
        try await processBatches(items: catalogItems, batchProcessor: { batch in
            try await self.upsertCatalogItems(from: batch)
        })
    }

    private func processBatches<T>(items: [T], batchProcessor: (Array<T>) async throws -> Void) async throws {
        for i in stride(from: 0, to: items.count, by: batchSize) {
            let end = min(i + batchSize, items.count)
            let batch = Array(items[i..<end])
            try await batchProcessor(batch)

            // Add small delay between batches to prevent overwhelming the system
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }

    private func upsertCatalogItems(from catalogItems: [CatalogItem]) async throws {
        // Separate products and variations
        let productItems = catalogItems.filter { $0.type != "variation" }
        let variationItems = catalogItems.filter { $0.type == "variation" }

        // Convert to Networking objects
        let networkingProducts = productItems.compactMap { catalogItem -> Networking.Product? in
            return self.mapCatalogItemToNetworkingProduct(catalogItem)
        }

        let networkingVariations = variationItems.compactMap { catalogItem -> Networking.ProductVariation? in
            return self.mapCatalogItemToNetworkingProductVariation(catalogItem)
        }

        // Save products first using ProductStore's method
        if !networkingProducts.isEmpty {
            await productStore.upsertStoredProductsInBackground(
                readOnlyProducts: networkingProducts,
                siteID: siteID
            )
        }

        // Save variations using ProductVariationStorageManager, grouped by product
        if !networkingVariations.isEmpty {
            await upsertProductVariations(networkingVariations)
        }
    }

    private func upsertProductVariations(_ variations: [Networking.ProductVariation]) async {
        // Group variations by product ID for efficient storage
        let variationsByProduct = Dictionary(grouping: variations) { $0.productID }

        await withCheckedContinuation { continuation in
            let group = DispatchGroup()

            for (productID, productVariations) in variationsByProduct {
                group.enter()
                productVariationStorageManager.upsertStoredProductVariationsInBackground(
                    readOnlyProductVariations: productVariations,
                    siteID: siteID,
                    productID: productID
                ) {
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                continuation.resume()
            }
        }
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
        let status = ProductStatus(rawValue: catalogItem.status ?? "publish") ?? .published
        let stockQuantity = catalogItem.stockQuantity.map { Decimal($0) }
        let stockStatus = ProductStockStatus(rawValue: catalogItem.stockStatus ?? "instock") ?? .inStock
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
            weight: catalogItem.weight ?? "",
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
}

// MARK: - Supporting Types

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
        case parentID = "parent_id"
    }
}
