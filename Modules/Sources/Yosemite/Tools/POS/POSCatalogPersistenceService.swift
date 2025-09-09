// periphery:ignore:all
import Foundation
import Storage

enum POSCatalogPersistenceError: Error, Equatable {
    case siteNotFound(siteID: Int64)
}

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

    /// Loads the POS site for the given site ID
    /// - Parameter siteID: The site ID to load the POSSite for
    /// - Returns: The loaded POSSite or nil if not found in storage
    func loadSite(siteID: Int64) async throws -> POSSite?

    /// Updates the PersistedSite based on POSSite data
    /// - Parameter site: The POSSite containing the updated data
    func updateSite(_ site: POSSite) async throws
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

            let site = PersistedSite(id: siteID)
            try site.insert(db)

            for product in catalog.productsToPersist {
                try product.insert(db, onConflict: .ignore)
            }

            for image in catalog.productImagesToPersist {
                try image.insert(db, onConflict: .ignore)
            }

            for var attribute in catalog.productAttributesToPersist {
                try attribute.insert(db)
            }

            for variation in catalog.variationsToPersist {
                try variation.insert(db, onConflict: .ignore)
            }

            for image in catalog.variationImagesToPersist {
                try image.insert(db, onConflict: .ignore)
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
            let site = PersistedSite(id: siteID)
            try site.insert(db, onConflict: .ignore)

            for product in catalog.productsToPersist {
                try product.insert(db, onConflict: .replace)
            }

            let productIDs = catalog.products.map { $0.productID }.map { String($0) }.joined(separator: ",")

            try PersistedProductImage
                .filter(sql: "\(PersistedProductImage.Columns.productID.name) IN (\(productIDs))")
                .deleteAll(db)
            for image in catalog.productImagesToPersist {
                try image.insert(db, onConflict: .replace)
            }

            try PersistedProductAttribute
                .filter(sql: "\(PersistedProductAttribute.Columns.productID.name) IN (\(productIDs))")
                .deleteAll(db)
            for var attribute in catalog.productAttributesToPersist {
                try attribute.insert(db)
            }

            for variation in catalog.variationsToPersist {
                try variation.insert(db, onConflict: .replace)
            }

            let variationIDs = catalog.variations.map { $0.productVariationID }.map { String($0) }.joined(separator: ",")

            try PersistedProductVariationImage
                .filter(sql: "\(PersistedProductVariationImage.Columns.productVariationID.name) IN (\(variationIDs))")
                .deleteAll(db)
            for image in catalog.variationImagesToPersist {
                try image.insert(db, onConflict: .replace)
            }

            try PersistedProductVariationAttribute
                .filter(sql: "\(PersistedProductVariationAttribute.Columns.productVariationID.name) IN (\(variationIDs))")
                .deleteAll(db)
            for var attribute in catalog.variationAttributesToPersist {
                try attribute.insert(db)
            }
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

    func loadSite(siteID: Int64) async throws -> POSSite? {
        try await grdbManager.databaseConnection.read { db in
            try PersistedSite.filter(key: siteID).fetchOne(db)?.toPOSSite()
        }
    }

    func updateSite(_ site: POSSite) async throws {
        try await grdbManager.databaseConnection.write { db in
            guard try PersistedSite.filter(key: site.siteID).fetchOne(db) != nil else {
                throw POSCatalogPersistenceError.siteNotFound(siteID: site.siteID)
            }

            let persistedSite = PersistedSite(from: site)
            try persistedSite.update(db)
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
