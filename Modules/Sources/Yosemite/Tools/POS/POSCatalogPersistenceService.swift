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
            // currently, we can't save for more than one site as entity IDs are not namespaced.
            try PersistedSite.deleteAll(db)

            let site = PersistedSite(id: siteID, lastCatalogFullSyncDate: catalog.syncDate)
            try site.insert(db)

            for product in catalog.productsToPersist {
                try product.insert(db, onConflict: .replace)
            }

            for image in catalog.productImagesToPersist {
                try image.insert(db, onConflict: .replace)
            }

            for var attribute in catalog.productAttributesToPersist {
                try attribute.insert(db)
            }

            for variation in catalog.variationsToPersist {
                try variation.insert(db, onConflict: .replace)
            }

            for image in catalog.variationImagesToPersist {
                try image.insert(db, onConflict: .replace)
            }

            for var attribute in catalog.variationAttributesToPersist {
                try attribute.insert(db)
            }
        }

        DDLogInfo("✅ Catalog persistence complete")

        try await grdbManager.databaseConnection.read { db in
            let productCount = try PersistedProduct.fetchCount(db)
            let productImageCount = try PersistedProductImage.fetchCount(db)
            let productAttributeCount = try PersistedProductAttribute.fetchCount(db)
            let variationCount = try PersistedProductVariation.fetchCount(db)
            let variationImageCount = try PersistedProductVariationImage.fetchCount(db)
            let variationAttributeCount = try PersistedProductVariationAttribute.fetchCount(db)

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

                try PersistedProductImage
                    .filter { $0.productID == product.id }
                    .deleteAll(db)

                try PersistedProductAttribute
                    .filter { $0.productID == product.id }
                    .deleteAll(db)
            }

            for image in catalog.productImagesToPersist {
                try image.insert(db, onConflict: .replace)
            }

            for var attribute in catalog.productAttributesToPersist {
                try attribute.insert(db, onConflict: .replace)
            }

            for variation in catalog.variationsToPersist {
                try variation.insert(db, onConflict: .replace)

                try PersistedProductVariationImage
                    .filter { $0.productVariationID == variation.id }
                    .deleteAll(db)

                try PersistedProductVariationAttribute
                    .filter { $0.productVariationID == variation.id }
                    .deleteAll(db)
            }

            for image in catalog.variationImagesToPersist {
                try image.insert(db, onConflict: .replace)
            }

            for var attribute in catalog.variationAttributesToPersist {
                try attribute.insert(db, onConflict: .replace)
            }

            var site = try PersistedSite.fetchOne(db, key: siteID)
            try site?.updateChanges(db) { $0.lastCatalogIncrementalSyncDate = catalog.syncDate }
        }

        DDLogInfo("✅ Incremental catalog persistence complete")

        try await grdbManager.databaseConnection.read { db in
            let productCount = try PersistedProduct.fetchCount(db)
            let productImageCount = try PersistedProductImage.fetchCount(db)
            let productAttributeCount = try PersistedProductAttribute.fetchCount(db)
            let variationCount = try PersistedProductVariation.fetchCount(db)
            let variationImageCount = try PersistedProductVariationImage.fetchCount(db)
            let variationAttributeCount = try PersistedProductVariationAttribute.fetchCount(db)

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

    var productImagesToPersist: [PersistedProductImage] {
        products.flatMap { product in
            product.images.map { PersistedProductImage(from: $0, productID: product.productID) }
        }
    }

    var productAttributesToPersist: [PersistedProductAttribute] {
        products.flatMap { product in
            product.attributes.map { PersistedProductAttribute(from: $0, productID: product.productID) }
        }
    }

    var variationsToPersist: [PersistedProductVariation] {
        variations.map { PersistedProductVariation(from: $0) }
    }

    var variationImagesToPersist: [PersistedProductVariationImage] {
        variations.compactMap { variation in
            variation.image.map { PersistedProductVariationImage(from: $0, productVariationID: variation.productVariationID) }
        }
    }

    var variationAttributesToPersist: [PersistedProductVariationAttribute] {
        variations.flatMap { variation in
            variation.attributes.map { PersistedProductVariationAttribute(from: $0, productVariationID: variation.productVariationID) }
        }
    }
}
