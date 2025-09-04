import Foundation
import Storage

public protocol POSCatalogPersistenceServiceProtocol {
    /// Clears all catalog data for the specified site
    /// - Parameter siteID: The site ID to clear data for
    func clearSiteData(for siteID: Int64) async throws

    /// Persists catalog data to the database
    /// - Parameters:
    ///   - catalog: The catalog to persist
    ///   - siteID: The site ID to associate the catalog with
    func persistCatalog(_ catalog: POSCatalog, siteID: Int64) async throws

    /// Clears existing data and persists new catalog data
    /// - Parameters:
    ///   - catalog: The catalog to persist
    ///   - siteID: The site ID to associate the catalog with
    func replaceAllCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws
}

public final class POSCatalogPersistenceService: POSCatalogPersistenceServiceProtocol {
    private let grdbManager: GRDBManagerProtocol

    public init(grdbManager: GRDBManagerProtocol) {
        self.grdbManager = grdbManager
    }

    public func clearSiteData(for siteID: Int64) async throws {
        let db = grdbManager.databaseConnection
        try await db.write { db in
            DDLogInfo("🗑️ Clearing catalog data for site \(siteID)")
            // currently, we can't save for more than one site as entity IDs are not namespaced.
            try PersistedSite.deleteAll(db)
//            try PersistedSite.deleteOne(db, key: siteID)
        }
    }

    public func persistCatalog(_ catalog: POSCatalog, siteID: Int64) async throws {
        DDLogInfo("💾 Persisting catalog with \(catalog.products.count) products and \(catalog.variations.count) variations")

        try await grdbManager.databaseConnection.write { db in
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

    public func replaceAllCatalogData(_ catalog: POSCatalog, siteID: Int64) async throws {
        try await clearSiteData(for: siteID)
        try await persistCatalog(catalog, siteID: siteID)
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
