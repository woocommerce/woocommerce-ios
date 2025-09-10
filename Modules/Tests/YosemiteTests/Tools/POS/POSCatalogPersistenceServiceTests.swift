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

    @Test func replaceAllCatalogData_removes_related_images_and_attributes_for_products() async throws {
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

    @Test func replaceAllCatalogData_removes_related_images_and_attributes_for_variations() async throws {
        // Given - existing data with variation relations
        let parentProduct = POSProduct.fake().copy(
            siteID: sampleSiteID,
            productID: 10
        )
        let existingVariation = POSProductVariation.fake().copy(
            siteID: sampleSiteID,
            productID: 10,
            productVariationID: 5,
            attributes: [ProductVariationAttribute.fake()],
            image: ProductImage.fake().copy(imageID: 500)
        )
        let existingCatalog = POSCatalog(products: [parentProduct], variations: [existingVariation])
        try await sut.replaceAllCatalogData(existingCatalog, siteID: sampleSiteID)

        // When - replace with catalog containing only parent product (no variations)
        let catalogWithoutVariations = POSCatalog(products: [parentProduct], variations: [])
        try await sut.replaceAllCatalogData(catalogWithoutVariations, siteID: sampleSiteID)

        // Then - variation and its related data should be gone
        let db = grdbManager.databaseConnection
        try await db.read { db in
            let productCount = try PersistedProduct.fetchCount(db)
            let variationCount = try PersistedProductVariation.fetchCount(db)
            let variationImageCount = try PersistedProductVariationImage.fetchCount(db)
            let variationAttributeCount = try PersistedProductVariationAttribute.fetchCount(db)

            #expect(productCount == 1) // Parent product should remain
            #expect(variationCount == 0) // Variation should be gone
            #expect(variationImageCount == 0) // Variation image should be gone
            #expect(variationAttributeCount == 0) // Variation attributes should be gone
        }
    }

    // MARK: - Incremental Catalog Data Tests

    @Test func persistIncrementalCatalogData_inserts_new_products_when_database_is_empty() async throws {
        // Given
        try await sut.replaceAllCatalogData(.init(products: [], variations: []), siteID: sampleSiteID)

        let newProducts = [
            POSProduct.fake().copy(siteID: sampleSiteID, productID: 6),
            POSProduct.fake().copy(siteID: sampleSiteID, productID: 2)
        ]
        let catalog = POSCatalog(products: newProducts, variations: [])

        // When
        try await sut.persistIncrementalCatalogData(catalog, siteID: sampleSiteID)

        // Then
        let db = grdbManager.databaseConnection
        try await db.read { db in
            let siteCount = try PersistedSite.fetchCount(db)
            let productCount = try PersistedProduct.fetchCount(db)
            #expect(siteCount == 1)
            #expect(productCount == 2)

            let products = try PersistedProduct.filter(sql: "\(PersistedProduct.Columns.siteID.name) = \(sampleSiteID)").fetchAll(db)
            let productIDs = products.map { $0.id }.sorted()
            #expect(productIDs == [2, 6])
        }
    }

    @Test func persistIncrementalCatalogData_updates_existing_product() async throws {
        // Given
        let existingProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1, name: "Old Name")
        try await insertProduct(existingProduct)

        // When
        let updatedProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1, name: "New Name")
        let updateCatalog = POSCatalog(products: [updatedProduct], variations: [])
        try await sut.persistIncrementalCatalogData(updateCatalog, siteID: sampleSiteID)

        // Then
        try await grdbManager.databaseConnection.read { db in
            let productCount = try PersistedProduct.fetchCount(db)
            #expect(productCount == 1)

            let product = try PersistedProduct.fetchOne(db)
            #expect(product?.name == "New Name")
            #expect(product?.id == 1)
        }
    }

    @Test func persistIncrementalCatalogData_replaces_attributes_for_updated_product() async throws {
        // Given
        let attribute1 = Yosemite.ProductAttribute.fake().copy(name: "Color", options: ["Indigo", "Blue"])
        let attribute2 = Yosemite.ProductAttribute.fake().copy(name: "Size")
        let product = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1, attributes: [attribute1, attribute2])
        try await insertProduct(product)

        // When
        let updatedAttribute1 = attribute1.copy(options: ["Cardinal", "Blue"])
        let newAttribute = ProductAttribute.fake().copy(name: "Material")
        let updatedProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1, attributes: [newAttribute, updatedAttribute1])
        let updateCatalog = POSCatalog(products: [updatedProduct], variations: [])
        try await sut.persistIncrementalCatalogData(updateCatalog, siteID: sampleSiteID)

        // Then
        try await grdbManager.databaseConnection.read { db in
            let attributeCount = try PersistedProductAttribute.fetchCount(db)
            #expect(attributeCount == 2)

            let attributes = try PersistedProductAttribute.fetchAll(db).sorted(by: { $0.name < $1.name })
            #expect(attributes[0].name == "Color")
            #expect(attributes[0].options == ["Cardinal", "Blue"])
            #expect(attributes[0].productID == 1)
            #expect(attributes[1].name == "Material")
            #expect(attributes[1].options == [])
            #expect(attributes[1].productID == 1)
        }
    }

    @Test func persistIncrementalCatalogData_replaces_images_for_updated_product() async throws {
        // Given
        let image1 = ProductImage.fake().copy(imageID: 1, src: "https://example.com/image1.jpg")
        let image2 = ProductImage.fake().copy(imageID: 2, src: "https://example.com/image2.jpg")
        let product = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1, images: [image2, image1])
        try await insertProduct(product)

        // When
        let updatedImage1 = image1.copy(src: "https://example.com/image1-1.jpg")
        let newImage = ProductImage.fake().copy(imageID: 3, src: "https://example.com/image3.jpg")
        let updatedProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1, images: [newImage, updatedImage1])
        let updateCatalog = POSCatalog(products: [updatedProduct], variations: [])
        try await sut.persistIncrementalCatalogData(updateCatalog, siteID: sampleSiteID)

        // Then
        try await grdbManager.databaseConnection.read { db in
            let attributeCount = try PersistedProductImage.fetchCount(db)
            #expect(attributeCount == 2)

            let attributes = try PersistedProductImage.fetchAll(db).sorted(by: { $0.id < $1.id })
            #expect(attributes[0].src == "https://example.com/image1-1.jpg")
            #expect(attributes[0].productID == 1)
            #expect(attributes[1].src == "https://example.com/image3.jpg")
            #expect(attributes[1].productID == 1)
        }
    }

    @Test func persistIncrementalCatalogData_replaces_products_with_existing_and_new_products() async throws {
        // Given
        let existingProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1, name: "Existing")
        try await insertProduct(existingProduct)

        // When
        let updatedExistingProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1, name: "Updated Existing")
        let newProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 2, name: "New Product")
        let mixedCatalog = POSCatalog(products: [updatedExistingProduct, newProduct], variations: [])
        try await sut.persistIncrementalCatalogData(mixedCatalog, siteID: sampleSiteID)

        // Then
        try await grdbManager.databaseConnection.read { db in
            let productCount = try PersistedProduct.fetchCount(db)
            #expect(productCount == 2)

            let products = try PersistedProduct.fetchAll(db).sorted(by: { $0.id < $1.id })
            #expect(products[0].name == "Updated Existing")
            #expect(products[0].id == 1)
            #expect(products[1].name == "New Product")
            #expect(products[1].id == 2)
        }
    }

    @Test func persistIncrementalCatalogData_inserts_new_variations_when_database_is_empty() async throws {
        // Given
        try await sut.replaceAllCatalogData(.init(products: [], variations: []), siteID: sampleSiteID)

        let parentProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 10)
        let newVariations = [
            POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 10, productVariationID: 6),
            POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 10, productVariationID: 2)
        ]
        let catalog = POSCatalog(products: [parentProduct], variations: newVariations)

        // When
        try await sut.persistIncrementalCatalogData(catalog, siteID: sampleSiteID)

        // Then
        let db = grdbManager.databaseConnection
        try await db.read { db in
            let siteCount = try PersistedSite.fetchCount(db)
            let variationCount = try PersistedProductVariation.fetchCount(db)
            #expect(siteCount == 1)
            #expect(variationCount == 2)

            let variations = try PersistedProductVariation.filter(sql: "\(PersistedProductVariation.Columns.siteID.name) = \(sampleSiteID)").fetchAll(db)
            let variationIDs = variations.map { $0.id }.sorted()
            #expect(variationIDs == [2, 6])
        }
    }

    @Test func persistIncrementalCatalogData_updates_existing_variation() async throws {
        // Given
        let parentProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 10)
        let existingVariation = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 10, productVariationID: 1, price: "10.00")
        try await insertProduct(parentProduct)
        try await insertVariation(existingVariation)

        // When
        let updatedVariation = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 10, productVariationID: 1, price: "15.00")
        let updateCatalog = POSCatalog(products: [parentProduct], variations: [updatedVariation])
        try await sut.persistIncrementalCatalogData(updateCatalog, siteID: sampleSiteID)

        // Then
        try await grdbManager.databaseConnection.read { db in
            let variationCount = try PersistedProductVariation.fetchCount(db)
            #expect(variationCount == 1)

            let variation = try PersistedProductVariation.fetchOne(db)
            #expect(variation?.price == "15.00")
            #expect(variation?.id == 1)
        }
    }

    @Test func persistIncrementalCatalogData_replaces_attributes_for_updated_variation() async throws {
        // Given
        let parentProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 10)
        let attribute1 = Yosemite.ProductVariationAttribute.fake().copy(name: "Color", option: "Blue")
        let attribute2 = Yosemite.ProductVariationAttribute.fake().copy(name: "Size", option: "M")
        let variation = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 10, productVariationID: 1, attributes: [attribute1, attribute2])
        try await insertProduct(parentProduct)
        try await insertVariation(variation)

        // When
        let updatedAttribute1 = attribute1.copy(option: "Cardinal")
        let newAttribute = ProductVariationAttribute.fake().copy(name: "Material", option: "Cotton")
        let updatedVariation = variation.copy(attributes: [newAttribute, updatedAttribute1])
        let updateCatalog = POSCatalog(products: [parentProduct], variations: [updatedVariation])
        try await sut.persistIncrementalCatalogData(updateCatalog, siteID: sampleSiteID)

        // Then
        try await grdbManager.databaseConnection.read { db in
            let attributeCount = try PersistedProductVariationAttribute.fetchCount(db)
            #expect(attributeCount == 2)

            let attributes = try PersistedProductVariationAttribute.fetchAll(db).sorted(by: { $0.name < $1.name })
            #expect(attributes[0].name == "Color")
            #expect(attributes[0].option == "Cardinal")
            #expect(attributes[0].productVariationID == 1)
            #expect(attributes[1].name == "Material")
            #expect(attributes[1].option == "Cotton")
            #expect(attributes[1].productVariationID == 1)
        }
    }

    @Test func persistIncrementalCatalogData_replaces_image_for_updated_variation() async throws {
        // Given
        let parentProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 10)
        let image = ProductImage.fake().copy(imageID: 1, src: "https://example.com/variation1.jpg")
        let variation = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 10, productVariationID: 1, image: image)
        try await insertProduct(parentProduct)
        try await insertVariation(variation)

        // When
        let updatedImage = image.copy(src: "https://example.com/variation1-updated.jpg")
        let updatedVariation = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 10, productVariationID: 1, image: updatedImage)
        let updateCatalog = POSCatalog(products: [parentProduct], variations: [updatedVariation])
        try await sut.persistIncrementalCatalogData(updateCatalog, siteID: sampleSiteID)

        // Then
        try await grdbManager.databaseConnection.read { db in
            let imageCount = try PersistedProductVariationImage.fetchCount(db)
            #expect(imageCount == 1)

            let image = try PersistedProductVariationImage.fetchOne(db)
            #expect(image?.src == "https://example.com/variation1-updated.jpg")
            #expect(image?.productVariationID == 1)
        }
    }

    @Test func persistIncrementalCatalogData_upserts_existing_and_new_variations() async throws {
        // Given
        let parentProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 10)
        let existingVariation = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 10, productVariationID: 1, price: "10.00")
        try await insertProduct(parentProduct)
        try await insertVariation(existingVariation)

        // When
        let updatedExistingVariation = existingVariation.copy(price: "12.00")
        let newVariation = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 10, productVariationID: 2, price: "8.00")
        let mixedCatalog = POSCatalog(products: [parentProduct], variations: [updatedExistingVariation, newVariation])
        try await sut.persistIncrementalCatalogData(mixedCatalog, siteID: sampleSiteID)

        // Then
        try await grdbManager.databaseConnection.read { db in
            let variationCount = try PersistedProductVariation.fetchCount(db)
            #expect(variationCount == 2)

            let variations = try PersistedProductVariation.fetchAll(db).sorted(by: { $0.id < $1.id })
            #expect(variations[0].price == "12.00")
            #expect(variations[0].id == 1)
            #expect(variations[1].price == "8.00")
            #expect(variations[1].id == 2)
        }
    }
}

private extension POSCatalogPersistenceServiceTests {
    func insertProduct(_ product: POSProduct) async throws {
        let db = grdbManager.databaseConnection
        try await db.write { db in
            try PersistedSite(id: sampleSiteID).insert(db, onConflict: .ignore)
        }
        try product.save(to: db)
    }

    func insertVariation(_ variation: POSProductVariation) async throws {
        let db = grdbManager.databaseConnection
        try variation.save(to: db)
    }
}
