// periphery:ignore:all
import Foundation
import Storage
import GRDB

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
            try PersistedSite.deleteOne(db, key: siteID)

            let site = PersistedSite(id: siteID, lastCatalogFullSyncDate: catalog.syncDate)
            try site.insert(db)

            for product in catalog.productsToPersist {
                try product.insert(db, onConflict: .replace)
            }

            for variation in catalog.variationsToPersist {
                try variation.insert(db, onConflict: .replace)
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

            for var attribute in catalog.productAttributesToPersist {
                try attribute.insert(db)
            }

            for var attribute in catalog.variationAttributesToPersist {
                try attribute.insert(db)
            }
        }

        DDLogInfo("✅ Catalog persistence complete")

        try await grdbManager.databaseConnection.read { db in
            let productCount = try PersistedProduct.filter { $0.siteID == siteID }.fetchCount(db)
            let productImageCount = try PersistedProductImage.filter { $0.siteID == siteID }.fetchCount(db)
            let productAttributeCount = try PersistedProductAttribute.filter { $0.siteID == siteID }.fetchCount(db)
            let variationCount = try PersistedProductVariation.filter { $0.siteID == siteID }.fetchCount(db)
            let variationImageCount = try PersistedProductVariationImage.filter { $0.siteID == siteID }.fetchCount(db)
            let variationAttributeCount = try PersistedProductVariationAttribute.filter { $0.siteID == siteID }.fetchCount(db)

            DDLogInfo("Persisted \(productCount) products, \(productImageCount) product images, " +
                      "\(productAttributeCount) product attributes, \(variationCount) variations, " +
                      "\(variationImageCount) variation images, \(variationAttributeCount) variation attributes")
        }
    }

    func persistIncrementalCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws {
        DDLogInfo("💾 Persisting incremental catalog with \(catalog.products.count) updated products, " +
                  "\(catalog.variations.count) updated variations, " +
                  "\(catalog.productsToRemove.count) products to remove")

        try await grdbManager.databaseConnection.write { db in
            for product in catalog.products {
                // Delete attributes for updated products, the remaining set will be recreated later in the save
                try PersistedProductAttribute
                    .filter(PersistedProductAttribute.Columns.productID == product.productID)
                    .deleteAll(db)

                try PersistedProduct(from: product).save(db)

                // Delete variations that are no longer associated with this product
                let existingVariations = try PersistedProductVariation
                    .filter(PersistedProductVariation.Columns.siteID == siteID)
                    .filter(PersistedProductVariation.Columns.productID == product.productID)
                    .fetchAll(db)

                for variation in existingVariations {
                    if !product.variationIDs.contains(variation.id) {
                        try variation.delete(db)
                    }
                }
            }

            for variation in catalog.variationsToPersist {
                // Delete attributes for updated variations, the remaining set will be recreated later in the save
                try PersistedProductVariationAttribute
                    .filter(PersistedProductVariationAttribute.Columns.productVariationID == variation.id)
                    .deleteAll(db)

                try variation.save(db)
            }

            // Upsert actual image data (shared by products and variations)
            for image in catalog.imagesToPersist {
                try image.save(db)
            }

            // Upsert new join table entries
            for image in catalog.productImagesToPersist {
                try image.save(db)
            }

            for image in catalog.variationImagesToPersist {
                try image.save(db)
            }

            for var attribute in catalog.productAttributesToPersist {
                try attribute.insert(db)
            }

            for var attribute in catalog.variationAttributesToPersist {
                try attribute.save(db)
            }

            var site = try PersistedSite.fetchOne(db, key: siteID)
            try site?.updateChanges(db) { $0.lastCatalogIncrementalSyncDate = catalog.syncDate }
        }

        // Delete products hidden from POS when detected during incremental sync
        // Variations are not tracked separately, they cascade delete in GRDB when their parent product is removed,
        // so there is no need to pass their IDs here.
        if !catalog.productsToRemove.isEmpty {
            try await deleteProducts(catalog.productsToRemove, variationIDs: [], siteID: siteID)
        }

        DDLogInfo("✅ Incremental catalog persistence complete")

        try await grdbManager.databaseConnection.read { db in
            let productCount = try PersistedProduct.filter { $0.siteID == siteID }.fetchCount(db)
            let productImageCount = try PersistedProductImage.filter { $0.siteID == siteID }.fetchCount(db)
            let productAttributeCount = try PersistedProductAttribute.filter { $0.siteID == siteID }.fetchCount(db)
            let variationCount = try PersistedProductVariation.filter { $0.siteID == siteID }.fetchCount(db)
            let variationImageCount = try PersistedProductVariationImage.filter { $0.siteID == siteID }.fetchCount(db)
            let variationAttributeCount = try PersistedProductVariationAttribute.filter { $0.siteID == siteID }.fetchCount(db)

            DDLogInfo("Total after incremental update: \(productCount) products, \(productImageCount) product images, " +
                      "\(productAttributeCount) product attributes, \(variationCount) variations, " +
                      "\(variationImageCount) variation images, \(variationAttributeCount) variation attributes")
        }
    }

    func deleteProducts(_ productIDs: [Int64], variationIDs: [Int64], siteID: Int64) async throws {
        DDLogInfo("🗑️ Deleting \(productIDs.count) products and \(variationIDs.count) variations from catalog")

        try await grdbManager.databaseConnection.write { db in
            // Batch delete products using filter
            if !productIDs.isEmpty {
                let deletedProductsCount = try PersistedProduct
                    .filter(PersistedProduct.Columns.siteID == siteID)
                    .filter(productIDs.contains(PersistedProduct.Columns.id))
                    .deleteAll(db)
                DDLogInfo("Deleted \(deletedProductsCount) products from catalog")
            }

            // Batch delete variations using filter
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
        let variations = catalog.variations.filter { variation in
            let parentExists = productIDs.contains { $0 == variation.productID }
            if !parentExists {
                DDLogWarn("Variation \(variation.productVariationID) references missing product \(variation.productID) - it will not be available in POS.")
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

        let variationImages = variations.compactMap { variation -> PersistedImage? in
            guard let image = variation.image else { return nil }
            return PersistedImage.make(from: image, siteID: variation.siteID)
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
        variations.map { PersistedProductVariation(from: $0) }
    }

    // Join table entries for variation-image relationships
    var variationImagesToPersist: [PersistedProductVariationImage] {
        variations.compactMap { variation in
            variation.image.map { PersistedProductVariationImage(siteID: variation.siteID,
                                                                 productVariationID: variation.productVariationID,
                                                                 imageID: $0.imageID) }
        }
    }

    var variationAttributesToPersist: [PersistedProductVariationAttribute] {
        variations.flatMap { variation in
            variation.attributes.map { PersistedProductVariationAttribute(from: $0,
                                                                          siteID: variation.siteID,
                                                                          productVariationID: variation.productVariationID) }
        }
    }
}
