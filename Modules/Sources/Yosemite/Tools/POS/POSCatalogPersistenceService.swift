// periphery:ignore:all
import Foundation
import Storage
import GRDB
import struct Networking.POSTypedVariation

protocol POSCatalogPersistenceServiceProtocol {
    /// Clears existing data and persists new catalog data
    /// - Parameters:
    ///   - catalog: The catalog to persist
    ///   - siteID: The site ID to associate the catalog with
    func replaceAllCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws

    /// Persists incremental catalog data (insert/update)
    /// - Parameters:
    ///   - catalog: The catalog difference to persist
    ///   - siteID: The site ID to associate the catalog with
    func persistIncrementalCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws

    /// Deletes specific products and/or variations from the catalog
    /// - Parameters:
    ///   - productIDs: Product IDs to delete
    ///   - variationIDs: Variation IDs to delete
    ///   - siteID: The site ID
    func deleteProducts(_ productIDs: [Int64], variationIDs: [Int64], siteID: Int64) async throws
}

final class POSCatalogPersistenceService: POSCatalogPersistenceServiceProtocol {
    private let grdbManager: GRDBManagerProtocol

    init(grdbManager: GRDBManagerProtocol) {
        self.grdbManager = grdbManager
    }

    func replaceAllCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws {
        DDLogInfo("💾 Persisting catalog with \(catalog.products.count) products and \(catalog.variations.count) variations")

        let catalog = filterOrphanedVariations(from: catalog)

        try await grdbManager.databaseConnection.write { db in
            DDLogInfo("🗑️ Clearing catalog data for site \(siteID)")

            try POSSearchIndexBuilder.clearIndex(for: siteID, in: db)

            try PersistedSite.deleteOne(db, key: siteID)

            let site = PersistedSite(id: siteID, lastCatalogFullSyncDate: catalog.syncDate)
            try site.insert(db)

            let productNameLookup = Dictionary(catalog.products.map { ($0.productID, $0.name) }, uniquingKeysWith: { _, latest in latest })
            let variationAttributesLookup = Dictionary(grouping: catalog.variationAttributesToPersist) { $0.productVariationID }

            for product in catalog.productsToPersist {
                try product.insert(db, onConflict: .replace)
                // Filters by eligibility internally
                try POSSearchIndexBuilder.indexProduct(product, siteID: siteID, in: db)
            }

            for variation in catalog.variationsToPersist {
                try variation.insert(db, onConflict: .replace)
                let parentName = productNameLookup[variation.productID]
                let attributes = variationAttributesLookup[variation.id]?.map { $0.option } ?? []
                try POSSearchIndexBuilder.indexVariation(variation,
                                                         parentProductName: parentName,
                                                         attributes: attributes,
                                                         siteID: siteID,
                                                         in: db)
            }

            // Insert actual image data first (shared by products and variations)
            for image in catalog.imagesToPersist {
                try image.insert(db, onConflict: .replace)
            }

            // Then insert join table entries
            for productImage in catalog.productImagesToPersist {
                try productImage.insert(db, onConflict: .replace)
            }

            for variationImage in catalog.variationImagesToPersist {
                try variationImage.insert(db, onConflict: .replace)
            }

            // Insert attributes
            for var attribute in catalog.productAttributesToPersist {
                try attribute.insert(db)
            }

            for var attribute in catalog.variationAttributesToPersist {
                try attribute.insert(db)
            }
        }

        DDLogInfo("✅ Catalog persistence complete with inline FTS indexing")

        try await grdbManager.databaseConnection.read { db in
            let productCount = try PersistedProduct.filter { $0.siteID == siteID }.fetchCount(db)
            let productImageCount = try PersistedProductImage.filter { $0.siteID == siteID }.fetchCount(db)
            let productAttributeCount = try PersistedProductAttribute.filter { $0.siteID == siteID }.fetchCount(db)
            let variationCount = try PersistedProductVariation.filter { $0.siteID == siteID }.fetchCount(db)
            let variationImageCount = try PersistedProductVariationImage.filter { $0.siteID == siteID }.fetchCount(db)
            let variationAttributeCount = try PersistedProductVariationAttribute.filter { $0.siteID == siteID }.fetchCount(db)
            let indexCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM pos_search_fts WHERE siteID = ?", arguments: [siteID]) ?? 0

            DDLogInfo("Persisted \(productCount) products, \(productImageCount) product images, " +
                      "\(productAttributeCount) product attributes, \(variationCount) variations, " +
                      "\(variationImageCount) variation images, \(variationAttributeCount) variation attributes, " +
                      "\(indexCount) FTS entries")
        }
    }

    func persistIncrementalCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws {
        DDLogInfo("💾 Persisting incremental catalog with \(catalog.products.count) updated products, " +
                  "\(catalog.variations.count) updated variations, " +
                  "\(catalog.productsToRemove.count) products to remove")

        let productNameLookup = Dictionary(catalog.products.map { ($0.productID, $0.name) }, uniquingKeysWith: { _, latest in latest })
        let variationAttributesLookup = Dictionary(grouping: catalog.variationAttributesToPersist) { $0.productVariationID }

        try await grdbManager.databaseConnection.write { db in
            for product in catalog.products {
                // Remove old FTS entry before updating
                try POSSearchIndexBuilder.removeFromIndex(itemID: product.productID,
                                                          itemType: .product,
                                                          siteID: siteID,
                                                          in: db)

                // Delete attributes for updated products, the remaining set will be recreated later in the save
                try PersistedProductAttribute
                    .filter(PersistedProductAttribute.Columns.productID == product.productID)
                    .deleteAll(db)

                let persistedProduct = PersistedProduct(from: product)
                try persistedProduct.save(db)

                try POSSearchIndexBuilder.indexProduct(persistedProduct, siteID: siteID, in: db)

                // Delete variations that are no longer associated with this product
                let existingVariations = try PersistedProductVariation
                    .filter(PersistedProductVariation.Columns.siteID == siteID)
                    .filter(PersistedProductVariation.Columns.productID == product.productID)
                    .fetchAll(db)

                for variation in existingVariations {
                    if !product.variationIDs.contains(variation.id) {
                        try POSSearchIndexBuilder.removeFromIndex(itemID: variation.id,
                                                                  itemType: .variation,
                                                                  siteID: siteID,
                                                                  in: db)
                        try variation.delete(db)
                    }
                }
            }

            for variation in catalog.variationsToPersist {
                // Remove old FTS entry before updating
                try POSSearchIndexBuilder.removeFromIndex(itemID: variation.id,
                                                          itemType: .variation,
                                                          siteID: siteID,
                                                          in: db)

                // Delete attributes for updated variations, the remaining set will be recreated later in the save
                try PersistedProductVariationAttribute
                    .filter(PersistedProductVariationAttribute.Columns.productVariationID == variation.id)
                    .deleteAll(db)

                try variation.save(db)

                let parentName = productNameLookup[variation.productID]
                let attributes = variationAttributesLookup[variation.id]?.map { $0.option } ?? []
                try POSSearchIndexBuilder.indexVariation(variation,
                                                         parentProductName: parentName,
                                                         attributes: attributes,
                                                         siteID: siteID,
                                                         in: db)
            }

            // Upsert images
            for image in catalog.imagesToPersist {
                try image.save(db)
            }

            for image in catalog.productImagesToPersist {
                try image.save(db)
            }

            for image in catalog.variationImagesToPersist {
                try image.save(db)
            }

            // Insert attributes
            for var attribute in catalog.productAttributesToPersist {
                try attribute.insert(db)
            }

            for var attribute in catalog.variationAttributesToPersist {
                try attribute.save(db)
            }

            var site = try PersistedSite.fetchOne(db, key: siteID)
            try site?.updateChanges(db) { $0.lastCatalogIncrementalSyncDate = catalog.syncDate }
        }

        // Delete products hidden from POS (FTS entries removed inline via deleteProducts)
        if !catalog.productsToRemove.isEmpty {
            try await deleteProducts(catalog.productsToRemove, variationIDs: [], siteID: siteID)
        }

        DDLogInfo("✅ Incremental catalog persistence complete with inline FTS updates")

        try await grdbManager.databaseConnection.read { db in
            let productCount = try PersistedProduct.filter { $0.siteID == siteID }.fetchCount(db)
            let productImageCount = try PersistedProductImage.filter { $0.siteID == siteID }.fetchCount(db)
            let productAttributeCount = try PersistedProductAttribute.filter { $0.siteID == siteID }.fetchCount(db)
            let variationCount = try PersistedProductVariation.filter { $0.siteID == siteID }.fetchCount(db)
            let variationImageCount = try PersistedProductVariationImage.filter { $0.siteID == siteID }.fetchCount(db)
            let variationAttributeCount = try PersistedProductVariationAttribute.filter { $0.siteID == siteID }.fetchCount(db)
            let indexCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM pos_search_fts WHERE siteID = ?", arguments: [siteID]) ?? 0

            DDLogInfo("Total after incremental update: \(productCount) products, \(productImageCount) product images, " +
                      "\(productAttributeCount) product attributes, \(variationCount) variations, " +
                      "\(variationImageCount) variation images, \(variationAttributeCount) variation attributes, " +
                      "\(indexCount) FTS entries")
        }
    }

    func deleteProducts(_ productIDs: [Int64], variationIDs: [Int64], siteID: Int64) async throws {
        DDLogInfo("🗑️ Deleting \(productIDs.count) products and \(variationIDs.count) variations from catalog")

        try await grdbManager.databaseConnection.write { db in
            for productID in productIDs {
                try POSSearchIndexBuilder.removeFromIndex(itemID: productID,
                                                          itemType: .product,
                                                          siteID: siteID,
                                                          in: db)
                // Also remove any variations of this product from the index.
                // This handles cascade-deleted variations whose IDs we don't have.
                try POSSearchIndexBuilder.removeVariationsFromIndex(parentProductID: productID,
                                                                    siteID: siteID,
                                                                    in: db)
            }

            for variationID in variationIDs {
                try POSSearchIndexBuilder.removeFromIndex(itemID: variationID,
                                                          itemType: .variation,
                                                          siteID: siteID,
                                                          in: db)
            }

            if !productIDs.isEmpty {
                let deletedProductsCount = try PersistedProduct
                    .filter(PersistedProduct.Columns.siteID == siteID)
                    .filter(productIDs.contains(PersistedProduct.Columns.id))
                    .deleteAll(db)
                DDLogInfo("Deleted \(deletedProductsCount) products from catalog")
            }

            if !variationIDs.isEmpty {
                let deletedVariationsCount = try PersistedProductVariation
                    .filter(PersistedProductVariation.Columns.siteID == siteID)
                    .filter(variationIDs.contains(PersistedProductVariation.Columns.id))
                    .deleteAll(db)
                DDLogInfo("Deleted \(deletedVariationsCount) variations from catalog")
            }
        }

        DDLogInfo("✅ Catalog deletion complete")
    }
}

private extension POSCatalogPersistenceService {
    /// Filters out variations whose parent products are not in the catalog.
    /// This can happen when the API returns public variations but their parent products are not public.
    func filterOrphanedVariations(from catalog: POSCatalog) -> POSCatalog {
        let productIDs = catalog.products.map { $0.productID }
        let variations = catalog.variations.filter { entry in
            let parentExists = productIDs.contains { $0 == entry.variation.productID }
            if !parentExists {
                DDLogWarn("Variation \(entry.variation.productVariationID) references missing product \(entry.variation.productID).")
            }
            return parentExists
        }
        return POSCatalog(products: catalog.products, variations: variations, syncDate: catalog.syncDate)
    }
}

private extension POSCatalog {
    var productsToPersist: [PersistedProduct] {
        products.map { PersistedProduct(from: $0) }
    }

    var imagesToPersist: [PersistedImage] {
        let productImages = products.flatMap { product in
            product.images.map { PersistedImage.make(from: $0, siteID: product.siteID) }
        }

        let variationImages = variations.compactMap { entry -> PersistedImage? in
            guard let image = entry.variation.image else { return nil }
            return PersistedImage.make(from: image, siteID: entry.variation.siteID)
        }

        return deduplicateImages(productImages + variationImages)
    }

    func deduplicateImages(_ images: [PersistedImage]) -> [PersistedImage] {
        // Deduplicate by imageID since multiple products/variations can share the same image
        // (siteID is the same for all images in a catalog)
        var imageDict = [Int64: PersistedImage]()

        for image in images {
            imageDict[image.id] = image
        }

        return Array(imageDict.values)
    }

    // Join table entries for product-image relationships
    var productImagesToPersist: [PersistedProductImage] {
        products.flatMap { product in
            product.images.map { PersistedProductImage(siteID: product.siteID,
                                                       productID: product.productID,
                                                       imageID: $0.imageID) }
        }
    }

    var productAttributesToPersist: [PersistedProductAttribute] {
        products.flatMap { product in
            product.attributes.map { PersistedProductAttribute(from: $0,
                                                               siteID: product.siteID,
                                                               productID: product.productID) }
        }
    }

    var variationsToPersist: [PersistedProductVariation] {
        variations.map { PersistedProductVariation(from: $0.variation, productTypeKey: $0.typeKey) }
    }

    // Join table entries for variation-image relationships
    var variationImagesToPersist: [PersistedProductVariationImage] {
        variations.compactMap { entry in
            entry.variation.image.map { PersistedProductVariationImage(siteID: entry.variation.siteID,
                                                                       productVariationID: entry.variation.productVariationID,
                                                                       imageID: $0.imageID) }
        }
    }

    var variationAttributesToPersist: [PersistedProductVariationAttribute] {
        variations.flatMap { entry in
            entry.variation.attributes.map { PersistedProductVariationAttribute(from: $0,
                                                                                siteID: entry.variation.siteID,
                                                                                productVariationID: entry.variation.productVariationID) }
        }
    }
}
