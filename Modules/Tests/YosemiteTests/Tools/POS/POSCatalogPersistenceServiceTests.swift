import Foundation
import Testing
@testable import Storage
@testable import Yosemite

struct POSCatalogPersistenceServiceTests {
    private let grdbManager: GRDBManager
    private let sut: POSCatalogPersistenceService
    private let sampleSiteID: Int64 = 134

    init() throws {
        self.grdbManager = try GRDBManager()
        self.sut = POSCatalogPersistenceService(grdbManager: grdbManager)
    }

    // MARK: - Replace Catalog Data Tests

    @Test func replaceAllCatalogData_saves_site_products_and_variations() async throws {
        // Given
        let catalog = POSCatalog(
            products: [
                POSProduct.fake().copy(siteID: sampleSiteID, productID: 1),
                POSProduct.fake().copy(siteID: sampleSiteID, productID: 2, productTypeKey: "variable")
            ],
            variations: [
                POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 2, productVariationID: 1),
                POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 2, productVariationID: 2)
            ]
        )

        // When
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // Then
        let db = grdbManager.databaseConnection
        try await db.read { db in
            let siteCount = try PersistedSite.fetchCount(db)
            let productCount = try PersistedProduct.fetchCount(db)
            let variationCount = try PersistedProductVariation.fetchCount(db)

            #expect(siteCount == 1)
            #expect(productCount == 2)
            #expect(variationCount == 2)

            let site = try PersistedSite.fetchOne(db)
            #expect(site?.id == sampleSiteID)
        }
    }

    @Test func replaceAllCatalogData_saves_product_images_and_attributes() async throws {
        // Given
        let productWithRelations = POSProduct.fake().copy(
            siteID: sampleSiteID,
            productID: 1,
            images: [ProductImage.fake().copy(imageID: 100), ProductImage.fake().copy(imageID: 101)],
            attributes: [ProductAttribute.fake(), ProductAttribute.fake()]
        )
        let catalog = POSCatalog(products: [productWithRelations], variations: [])

        // When
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // Then
        let db = grdbManager.databaseConnection
        try await db.read { db in
            let imageCount = try PersistedProductImage.fetchCount(db)
            let attributeCount = try PersistedProductAttribute.fetchCount(db)

            #expect(imageCount == 2)
            #expect(attributeCount == 2)
        }
    }

    @Test func replaceAllCatalogData_saves_variation_images_and_attributes() async throws {
        // Given
        let variationWithRelations = POSProductVariation.fake().copy(
            siteID: sampleSiteID,
            productID: 15,
            productVariationID: 1,
            attributes: [ProductVariationAttribute.fake(), ProductVariationAttribute.fake()], image: ProductImage.fake().copy(imageID: 200)
        )
        let catalog = POSCatalog(products: [POSProduct.fake().copy(siteID: sampleSiteID, productID: 15)],
                                 variations: [variationWithRelations])

        // When
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // Then
        let db = grdbManager.databaseConnection
        try await db.read { db in
            let imageCount = try PersistedProductVariationImage.fetchCount(db)
            let attributeCount = try PersistedProductVariationAttribute.fetchCount(db)

            #expect(imageCount == 1)
            #expect(attributeCount == 2)
        }
    }

    @Test func replaceAllCatalogData_handles_duplicate_image_ids_gracefully() async throws {
        // Given - products with same image ID
        let sharedImageID: Int64 = 300
        let product1 = POSProduct.fake().copy(
            siteID: sampleSiteID,
            productID: 1,
            images: [ProductImage.fake().copy(imageID: sharedImageID)]
        )
        let product2 = POSProduct.fake().copy(
            siteID: sampleSiteID,
            productID: 2,
            images: [ProductImage.fake().copy(imageID: sharedImageID)]
        )
        let catalog = POSCatalog(products: [product1, product2], variations: [])

        // When
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // Then - should not fail and should handle duplicates
        let db = grdbManager.databaseConnection
        try await db.read { db in
            let productCount = try PersistedProduct.fetchCount(db)
            let imageCount = try PersistedProductImage.fetchCount(db)

            #expect(productCount == 2)
            // While there's only one, the current implementation doesn't
            // have a join table so only one product has a reference to it
            #expect(imageCount == 1)
        }
    }

    @Test func replaceAllCatalogData_clears_existing_and_persists_new() async throws {
        // Given - existing data
        let existingCatalog = POSCatalog(
            products: [POSProduct.fake().copy(siteID: sampleSiteID, productID: 80)],
            variations: [POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 80, productVariationID: 100)]
        )
        try await sut.replaceAllCatalogData(existingCatalog, siteID: sampleSiteID)

        // When - replace with new data
        let newCatalog = POSCatalog(
            products: [POSProduct.fake().copy(siteID: sampleSiteID, productID: 180)],
            variations: [POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 180, productVariationID: 200)]
        )
        try await sut.replaceAllCatalogData(newCatalog, siteID: sampleSiteID)

        // Then - should have only new data
        let db = grdbManager.databaseConnection
        try await db.read { db in
            let productCount = try PersistedProduct.fetchCount(db)
            let variationCount = try PersistedProductVariation.fetchCount(db)

            #expect(productCount == 1)
            #expect(variationCount == 1)

            let product = try PersistedProduct.fetchOne(db)
            let variation = try PersistedProductVariation.fetchOne(db)

            #expect(product?.id == 180)
            #expect(variation?.id == 200)
        }
    }

    @Test func replaceAllCatalogData_removes_related_images_and_attributes() async throws {
        // Given - existing data with relations
        let existingProduct = POSProduct.fake().copy(
            siteID: sampleSiteID,
            productID: 1,
            images: [ProductImage.fake()],
            attributes: [ProductAttribute.fake()]
        )
        let existingCatalog = POSCatalog(products: [existingProduct], variations: [])
        try await sut.replaceAllCatalogData(existingCatalog, siteID: sampleSiteID)

        // When - replace with empty catalog
        let emptyCatalog = POSCatalog(products: [], variations: [])
        try await sut.replaceAllCatalogData(emptyCatalog, siteID: sampleSiteID)

        // Then - all related data should be gone
        let db = grdbManager.databaseConnection
        try await db.read { db in
            let productCount = try PersistedProduct.fetchCount(db)
            let imageCount = try PersistedProductImage.fetchCount(db)
            let attributeCount = try PersistedProductAttribute.fetchCount(db)

            #expect(productCount == 0)
            #expect(imageCount == 0)
            #expect(attributeCount == 0)
        }
    }
}
