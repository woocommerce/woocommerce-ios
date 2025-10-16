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
}

final class POSCatalogPersistenceService: POSCatalogPersistenceServiceProtocol {
    private let grdbManager: GRDBManagerProtocol

    init(grdbManager: GRDBManagerProtocol) {
        self.grdbManager = grdbManager
    }

    func replaceAllCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws {
        DDLogInfo("💾 Persisting catalog with \(catalog.products.count) products and \(catalog.variations.count) variations")

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
        DDLogInfo("💾 Persisting incremental catalog with \(catalog.products.count) products and \(catalog.variations.count) variations")

        try await grdbManager.databaseConnection.write { db in
            for product in catalog.productsToPersist {
                try product.insert(db, onConflict: .replace)

                // Delete old join table entries for this product
                try PersistedProductImage
                    .filter { $0.siteID == siteID && $0.productID == product.id }
                    .deleteAll(db)

                try PersistedProductAttribute
                    .filter { $0.siteID == siteID && $0.productID == product.id }
                    .deleteAll(db)
            }

            for variation in catalog.variationsToPersist {
                try variation.insert(db, onConflict: .replace)

                // Delete old join table entries for this variation
                try PersistedProductVariationImage
                    .filter { $0.siteID == siteID && $0.productVariationID == variation.id }
                    .deleteAll(db)

                try PersistedProductVariationAttribute
                    .filter { $0.siteID == siteID && $0.productVariationID == variation.id }
                    .deleteAll(db)
            }

            // Insert/update actual image data (shared by products and variations)
            for image in catalog.imagesToPersist {
                try image.insert(db, onConflict: .replace)
            }

            // Insert new join table entries
            for image in catalog.productImagesToPersist {
                try image.insert(db, onConflict: .replace)
            }

            for image in catalog.variationImagesToPersist {
                try image.insert(db, onConflict: .replace)
            }

            for var attribute in catalog.productAttributesToPersist {
                try attribute.insert(db, onConflict: .replace)
            }

            for var attribute in catalog.variationAttributesToPersist {
                try attribute.insert(db, onConflict: .replace)
            }

            var site = try PersistedSite.fetchOne(db, key: siteID)
            try site?.updateChanges(db) { $0.lastCatalogIncrementalSyncDate = catalog.syncDate }
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
