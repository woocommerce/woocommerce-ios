import Foundation
import Testing
@testable import Storage
@testable import Yosemite

struct POSCatalogPersistenceServiceTests {
    private let grdbManager: GRDBManager
    private let sut: POSCatalogPersistenceService
    private let sampleSiteID: Int64 = 134

    private var db: GRDBDatabaseConnection {
        grdbManager.databaseConnection
    }

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
            ],
            syncDate: .now
        )

        // When
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // Then
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
        let catalog = POSCatalog(products: [productWithRelations], variations: [], syncDate: .now)

        // When
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // Then
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
                                 variations: [variationWithRelations],
                                 syncDate: .now)

        // When
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // Then
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
        let catalog = POSCatalog(products: [product1, product2], variations: [], syncDate: .now)

        // When
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // Then - should not fail and should handle duplicates
        try await db.read { db in
            let productCount = try PersistedProduct.fetchCount(db)
            let joinCount = try PersistedProductImage.fetchCount(db)
            let imageCount = try PersistedImage.fetchCount(db)

            #expect(productCount == 2)
            // Two products share the same image, so:
            // - 2 join table entries (one per product)
            // - 1 actual image record (shared)
            #expect(joinCount == 2)
            #expect(imageCount == 1)
        }
    }

    @Test func replaceAllCatalogData_clears_existing_and_persists_new() async throws {
        // Given - existing data
        let existingCatalog = POSCatalog(
            products: [POSProduct.fake().copy(siteID: sampleSiteID, productID: 80)],
            variations: [POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 80, productVariationID: 100)],
            syncDate: .now
        )
        try await sut.replaceAllCatalogData(existingCatalog, siteID: sampleSiteID)

        // When - replace with new data
        let newCatalog = POSCatalog(
            products: [POSProduct.fake().copy(siteID: sampleSiteID, productID: 180)],
            variations: [POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 180, productVariationID: 200)],
            syncDate: .now
        )
        try await sut.replaceAllCatalogData(newCatalog, siteID: sampleSiteID)

        // Then - should have only new data
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
        let existingCatalog = POSCatalog(products: [existingProduct], variations: [], syncDate: .now)
        try await sut.replaceAllCatalogData(existingCatalog, siteID: sampleSiteID)

        // When - replace with empty catalog
        let emptyCatalog = POSCatalog(products: [], variations: [], syncDate: .now)
        try await sut.replaceAllCatalogData(emptyCatalog, siteID: sampleSiteID)

        // Then - all related data should be gone
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
        let existingCatalog = POSCatalog(products: [parentProduct], variations: [existingVariation], syncDate: .now)
        try await sut.replaceAllCatalogData(existingCatalog, siteID: sampleSiteID)

        // When - replace with catalog containing only parent product (no variations)
        let catalogWithoutVariations = POSCatalog(products: [parentProduct], variations: [], syncDate: .now)
        try await sut.replaceAllCatalogData(catalogWithoutVariations, siteID: sampleSiteID)

        // Then - variation and its related data should be gone
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
        try await sut.replaceAllCatalogData(.init(products: [], variations: [], syncDate: .now), siteID: sampleSiteID)

        let newProducts = [
            POSProduct.fake().copy(siteID: sampleSiteID, productID: 6),
            POSProduct.fake().copy(siteID: sampleSiteID, productID: 2)
        ]
        let catalog = POSCatalog(products: newProducts, variations: [], syncDate: .now)

        // When
        try await sut.persistIncrementalCatalogData(catalog, siteID: sampleSiteID)

        // Then
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
        let updateCatalog = POSCatalog(products: [updatedProduct], variations: [], syncDate: .now)
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
        let updateCatalog = POSCatalog(products: [updatedProduct], variations: [], syncDate: .now)
        try await sut.persistIncrementalCatalogData(updateCatalog, siteID: sampleSiteID)

        // Then
        try await grdbManager.databaseConnection.read { db in
            // Should have 2 attributes - old ones deleted, new ones added (no duplicates)
            let attributeCount = try PersistedProductAttribute.fetchCount(db)
            #expect(attributeCount == 2)

            let attributes = try PersistedProductAttribute.fetchAll(db).sorted(by: { $0.name < $1.name })
            #expect(attributes[0].name == "Color")
            #expect(attributes[0].options == ["Cardinal", "Blue"]) // Updated version
            #expect(attributes[1].name == "Material") // New attribute
        }
    }

    @Test func persistIncrementalCatalogData_prevents_duplicate_attributes_on_multiple_syncs() async throws {
        // Given - product with attributes
        let attribute1 = Yosemite.ProductAttribute.fake().copy(name: "Color", options: ["Red", "Blue"])
        let attribute2 = Yosemite.ProductAttribute.fake().copy(name: "Size", options: ["S", "M", "L"])
        let product = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1, attributes: [attribute1, attribute2])
        try await insertProduct(product)

        // When - perform multiple incremental syncs with the same product/attributes
        let catalog = POSCatalog(products: [product], variations: [], syncDate: .now)
        try await sut.persistIncrementalCatalogData(catalog, siteID: sampleSiteID)
        try await sut.persistIncrementalCatalogData(catalog, siteID: sampleSiteID)
        try await sut.persistIncrementalCatalogData(catalog, siteID: sampleSiteID)

        // Then - should have exactly 2 attributes, not duplicates
        try await grdbManager.databaseConnection.read { db in
            let attributeCount = try PersistedProductAttribute.fetchCount(db)
            #expect(attributeCount == 2)

            let attributes = try PersistedProductAttribute.fetchAll(db).sorted(by: { $0.name < $1.name })
            #expect(attributes[0].name == "Color")
            #expect(attributes[0].options == ["Red", "Blue"])
            #expect(attributes[1].name == "Size")
            #expect(attributes[1].options == ["S", "M", "L"])
        }
    }

    @Test func persistIncrementalCatalogData_updates_and_adds_images_for_updated_product_but_does_not_delete() async throws {
        // Given
        let image1 = ProductImage.fake().copy(imageID: 1, src: "https://example.com/image1.jpg")
        let image2 = ProductImage.fake().copy(imageID: 2, src: "https://example.com/image2.jpg")
        let product = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1, images: [image2, image1])
        try await insertProduct(product)

        // When
        let updatedImage1 = image1.copy(src: "https://example.com/image1-1.jpg")
        let newImage = ProductImage.fake().copy(imageID: 3, src: "https://example.com/image3.jpg")
        let updatedProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1, images: [newImage, updatedImage1])
        let updateCatalog = POSCatalog(products: [updatedProduct], variations: [], syncDate: .now)
        try await sut.persistIncrementalCatalogData(updateCatalog, siteID: sampleSiteID)

        // Then
        try await grdbManager.databaseConnection.read { db in
            // Check join table has correct count - should have 3 (original 2 + new 1, upsert keeps all)
            let joinCount = try PersistedProductImage.fetchCount(db)
            #expect(joinCount == 3)

            // Check join table entries
            let joins = try PersistedProductImage.fetchAll(db).sorted(by: { $0.imageID < $1.imageID })
            #expect(joins.count == 3)
            #expect(joins[0].productID == 1)
            #expect(joins[0].imageID == 1)
            #expect(joins[1].productID == 1)
            #expect(joins[1].imageID == 2) // Original image 2 join remains
            #expect(joins[2].productID == 1)
            #expect(joins[2].imageID == 3)

            // Check actual images - image 1 updated, image 2 unchanged, image 3 added
            let images = try PersistedImage.fetchAll(db).sorted(by: { $0.id < $1.id })
            #expect(images.count == 3)
            #expect(images[0].src == "https://example.com/image1-1.jpg") // Updated
            #expect(images[1].src == "https://example.com/image2.jpg") // Unchanged
            #expect(images[2].src == "https://example.com/image3.jpg") // New
        }
    }

    @Test func persistIncrementalCatalogData_replaces_products_with_existing_and_new_products() async throws {
        // Given
        let existingProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1, name: "Existing")
        try await insertProduct(existingProduct)

        // When
        let updatedExistingProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1, name: "Updated Existing")
        let newProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 2, name: "New Product")
        let mixedCatalog = POSCatalog(products: [updatedExistingProduct, newProduct], variations: [], syncDate: .now)
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
        try await sut.replaceAllCatalogData(.init(products: [], variations: [], syncDate: .now), siteID: sampleSiteID)

        let parentProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 10)
        let newVariations = [
            POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 10, productVariationID: 6),
            POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 10, productVariationID: 2)
        ]
        let catalog = POSCatalog(products: [parentProduct], variations: newVariations, syncDate: .now)

        // When
        try await sut.persistIncrementalCatalogData(catalog, siteID: sampleSiteID)

        // Then
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
        let updateCatalog = POSCatalog(products: [parentProduct], variations: [updatedVariation], syncDate: .now)
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
        let updateCatalog = POSCatalog(products: [parentProduct], variations: [updatedVariation], syncDate: .now)
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

    @Test func persistIncrementalCatalogData_prevents_duplicate_variation_attributes_on_multiple_syncs() async throws {
        // Given - variation with attributes
        let parentProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 10)
        let attribute1 = Yosemite.ProductVariationAttribute.fake().copy(name: "Color", option: "Red")
        let attribute2 = Yosemite.ProductVariationAttribute.fake().copy(name: "Size", option: "L")
        let variation = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 10, productVariationID: 1, attributes: [attribute1, attribute2])
        try await insertProduct(parentProduct)
        try await insertVariation(variation)

        // When - perform multiple incremental syncs with the same variation/attributes
        let catalog = POSCatalog(products: [parentProduct], variations: [variation], syncDate: .now)
        try await sut.persistIncrementalCatalogData(catalog, siteID: sampleSiteID)
        try await sut.persistIncrementalCatalogData(catalog, siteID: sampleSiteID)
        try await sut.persistIncrementalCatalogData(catalog, siteID: sampleSiteID)

        // Then - should have exactly 2 attributes, not duplicates
        try await grdbManager.databaseConnection.read { db in
            let attributeCount = try PersistedProductVariationAttribute.fetchCount(db)
            #expect(attributeCount == 2)

            let attributes = try PersistedProductVariationAttribute.fetchAll(db).sorted(by: { $0.name < $1.name })
            #expect(attributes[0].name == "Color")
            #expect(attributes[0].option == "Red")
            #expect(attributes[0].productVariationID == 1)
            #expect(attributes[1].name == "Size")
            #expect(attributes[1].option == "L")
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
        let updateCatalog = POSCatalog(products: [parentProduct], variations: [updatedVariation], syncDate: .now)
        try await sut.persistIncrementalCatalogData(updateCatalog, siteID: sampleSiteID)

        // Then
        try await grdbManager.databaseConnection.read { db in
            // Check join table
            let joinCount = try PersistedProductVariationImage.fetchCount(db)
            #expect(joinCount == 1)

            let join = try PersistedProductVariationImage.fetchOne(db)
            #expect(join?.productVariationID == 1)
            #expect(join?.imageID == 1)

            // Check actual image
            let image = try PersistedImage.fetchOne(db)
            #expect(image?.src == "https://example.com/variation1-updated.jpg")
        }
    }

    @Test func persistIncrementalCatalogData_replaces_variations_with_existing_and_new_variations() async throws {
        // Given
        let parentProduct = POSProduct.fake().copy(siteID: sampleSiteID, productID: 10)
        let existingVariation = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 10, productVariationID: 1, price: "10.00")
        try await insertProduct(parentProduct)
        try await insertVariation(existingVariation)

        // When
        let updatedExistingVariation = existingVariation.copy(price: "12.00")
        let newVariation = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 10, productVariationID: 2, price: "8.00")
        let mixedCatalog = POSCatalog(products: [parentProduct], variations: [updatedExistingVariation, newVariation], syncDate: .now)
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

    // MARK: - Sync Date Tracking Tests

    @Test func replaceAllCatalogData_stores_full_sync_date() async throws {
        // Given
        let syncDate = Date()
        let catalog = POSCatalog(products: [], variations: [], syncDate: syncDate)

        // When
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // Then
        try await db.read { db in
            let site = try PersistedSite.fetchOne(db, key: sampleSiteID)
            let storedDate = site?.lastCatalogFullSyncDate
            #expect(storedDate != nil)
            #expect(abs(storedDate!.timeIntervalSince(syncDate)) < 1.0) // Within 1 second tolerance
            #expect(site?.id == sampleSiteID)
        }
    }

    @Test func persistIncrementalCatalogData_deletes_variations_not_in_updated_product_variationIDs() async throws {
        // Given - a variable product with 3 variations
        let product = POSProduct.fake().copy(
            siteID: sampleSiteID,
            productID: 1,
            productTypeKey: "variable",
            variationIDs: [10, 20, 30]
        )
        let variation1 = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 1, productVariationID: 10)
        let variation2 = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 1, productVariationID: 20)
        let variation3 = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 1, productVariationID: 30)

        let catalog = POSCatalog(products: [product], variations: [variation1, variation2, variation3], syncDate: .now)
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // Verify initial state
        try await db.read { db in
            let variationCount = try PersistedProductVariation.fetchCount(db)
            #expect(variationCount == 3)
        }

        // When - incremental sync with updated product that only has 2 variations (removed variation 20)
        let updatedProduct = POSProduct.fake().copy(
            siteID: sampleSiteID,
            productID: 1,
            productTypeKey: "variable",
            variationIDs: [10, 30] // variation 20 removed
        )
        let incrementalCatalog = POSCatalog(products: [updatedProduct], variations: [], syncDate: .now)
        try await sut.persistIncrementalCatalogData(incrementalCatalog, siteID: sampleSiteID)

        // Then - variation 20 should be deleted, variations 10 and 30 should remain
        try await db.read { db in
            let variationCount = try PersistedProductVariation.fetchCount(db)
            #expect(variationCount == 2)

            let remainingVariations = try PersistedProductVariation.fetchAll(db).sorted(by: { $0.id < $1.id })
            #expect(remainingVariations.count == 2)
            #expect(remainingVariations[0].id == 10)
            #expect(remainingVariations[1].id == 30)
        }
    }

    @Test func persistIncrementalCatalogData_preserves_variations_not_mentioned_in_incremental_sync() async throws {
        // Given - two variable products with variations
        let product1 = POSProduct.fake().copy(
            siteID: sampleSiteID,
            productID: 1,
            productTypeKey: "variable",
            variationIDs: [10, 20]
        )
        let product2 = POSProduct.fake().copy(
            siteID: sampleSiteID,
            productID: 2,
            productTypeKey: "variable",
            variationIDs: [30, 40]
        )
        let variation10 = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 1, productVariationID: 10)
        let variation20 = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 1, productVariationID: 20)
        let variation30 = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 2, productVariationID: 30)
        let variation40 = POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 2, productVariationID: 40)

        let catalog = POSCatalog(
            products: [product1, product2],
            variations: [variation10, variation20, variation30, variation40],
            syncDate: .now
        )
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // When - incremental sync only updates product 1, product 2 not mentioned
        let updatedProduct1 = POSProduct.fake().copy(
            siteID: sampleSiteID,
            productID: 1,
            productTypeKey: "variable",
            variationIDs: [10] // removed variation 20
        )
        let incrementalCatalog = POSCatalog(products: [updatedProduct1], variations: [], syncDate: .now)
        try await sut.persistIncrementalCatalogData(incrementalCatalog, siteID: sampleSiteID)

        // Then - variation 20 deleted, but product 2's variations (30, 40) remain untouched
        try await db.read { db in
            let variationCount = try PersistedProductVariation.fetchCount(db)
            #expect(variationCount == 3)

            let remainingVariations = try PersistedProductVariation.fetchAll(db).sorted(by: { $0.id < $1.id })
            #expect(remainingVariations[0].id == 10)
            #expect(remainingVariations[0].productID == 1)
            #expect(remainingVariations[1].id == 30)
            #expect(remainingVariations[1].productID == 2)
            #expect(remainingVariations[2].id == 40)
            #expect(remainingVariations[2].productID == 2)
        }
    }

    @Test func persistIncrementalCatalogData_stores_incremental_sync_date() async throws {
        // Given - site with existing full sync date
        let fullSyncDate = Date().addingTimeInterval(-3600) // 1 hour ago
        try await sut.replaceAllCatalogData(POSCatalog(products: [], variations: [], syncDate: fullSyncDate), siteID: sampleSiteID)

        // When - perform incremental sync
        let incrementalSyncDate = Date()
        let catalog = POSCatalog(products: [POSProduct.fake().copy(siteID: sampleSiteID, productID: 1)], variations: [], syncDate: incrementalSyncDate)
        try await sut.persistIncrementalCatalogData(catalog, siteID: sampleSiteID)

        // Then - both dates should be stored
        try await db.read { db in
            let site = try PersistedSite.fetchOne(db, key: sampleSiteID)
            let storedFullSyncDate = site?.lastCatalogFullSyncDate
            let storedIncrementalSyncDate = site?.lastCatalogIncrementalSyncDate
            #expect(storedFullSyncDate != nil)
            #expect(storedIncrementalSyncDate != nil)
            #expect(abs(storedFullSyncDate!.timeIntervalSince(fullSyncDate)) < 1.0) // Within 1 second tolerance
            #expect(abs(storedIncrementalSyncDate!.timeIntervalSince(incrementalSyncDate)) < 1.0) // Within 1 second tolerance
            #expect(site?.id == sampleSiteID)
        }
    }

    @Test func replaceAllCatalogData_updates_existing_site_sync_date() async throws {
        // Given - existing site with old sync date
        let oldSyncDate = Date().addingTimeInterval(-7200) // 2 hours ago
        try await sut.replaceAllCatalogData(POSCatalog(products: [], variations: [], syncDate: oldSyncDate), siteID: sampleSiteID)

        // When - new full sync with updated date
        let newSyncDate = Date()
        let catalog = POSCatalog(products: [POSProduct.fake().copy(siteID: sampleSiteID, productID: 1)], variations: [], syncDate: newSyncDate)
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // Then - sync date should be updated
        try await db.read { db in
            let site = try PersistedSite.fetchOne(db, key: sampleSiteID)
            let storedDate = site?.lastCatalogFullSyncDate
            #expect(storedDate != nil)
            #expect(abs(storedDate!.timeIntervalSince(newSyncDate)) < 1.0) // Within 1 second tolerance
            #expect(site?.id == sampleSiteID)
        }
    }

    // MARK: - Orphaned Variation Filtering Tests

    @Test func replaceAllCatalogData_filters_out_variations_without_parent_products() async throws {
        // Given
        let product = POSProduct.fake().copy(siteID: sampleSiteID, productID: 10)
        let validVariation = POSProductVariation.fake()
            .copy(siteID: sampleSiteID, productID: 10, productVariationID: 1, image: ProductImage.fake().copy(imageID: 100))
        let orphanedVariation1 = POSProductVariation.fake()
            .copy(siteID: sampleSiteID, productID: 20, productVariationID: 2, image: ProductImage.fake().copy(imageID: 200))
        let orphanedVariation2 = POSProductVariation.fake()
            .copy(siteID: sampleSiteID, productID: 30, productVariationID: 3, image: ProductImage.fake().copy(imageID: 300))

        let catalog = POSCatalog(
            products: [product],
            variations: [validVariation, orphanedVariation1, orphanedVariation2],
            syncDate: .now
        )

        // When
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // Then
        try await db.read { db in
            let variationCount = try PersistedProductVariation.fetchCount(db)
            #expect(variationCount == 1)
            let variationImageCount = try PersistedProductVariationImage.fetchCount(db)
            #expect(variationImageCount == 1)

            let variation = try PersistedProductVariation.fetchOne(db)
            #expect(variation?.id == 1)
            #expect(variation?.productID == 10)
            let variationImage = try PersistedProductVariationImage.fetchOne(db)
            #expect(variationImage?.imageID == 100)
        }
    }

    // MARK: - Delete Products Tests

    @Test func deleteProducts_removes_specified_products_from_catalog() async throws {
        // Given
        let catalog = POSCatalog(
            products: [
                POSProduct.fake().copy(siteID: sampleSiteID, productID: 100),
                POSProduct.fake().copy(siteID: sampleSiteID, productID: 200),
                POSProduct.fake().copy(siteID: sampleSiteID, productID: 300)
            ],
            variations: [],
            syncDate: .now
        )
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // When
        try await sut.deleteProducts([100, 300], variationIDs: [], siteID: sampleSiteID)

        // Then
        try await db.read { db in
            let products = try PersistedProduct
                .filter(sql: "\(PersistedProduct.Columns.siteID.name) = \(sampleSiteID)")
                .fetchAll(db)
            #expect(products.count == 1)
            #expect(products.first?.id == 200)
        }
    }

    @Test func deleteProducts_removes_specified_variations_from_catalog() async throws {
        // Given
        let catalog = POSCatalog(
            products: [
                POSProduct.fake().copy(siteID: sampleSiteID, productID: 100, productTypeKey: "variable")
            ],
            variations: [
                POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 100, productVariationID: 500),
                POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 100, productVariationID: 501),
                POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 100, productVariationID: 502)
            ],
            syncDate: .now
        )
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // When
        try await sut.deleteProducts([], variationIDs: [500, 502], siteID: sampleSiteID)

        // Then
        try await db.read { db in
            let variations = try PersistedProductVariation
                .filter(sql: "\(PersistedProductVariation.Columns.siteID.name) = \(sampleSiteID)")
                .fetchAll(db)
            #expect(variations.count == 1)
            #expect(variations.first?.id == 501)
        }
    }

    @Test func deleteProducts_removes_both_products_and_variations() async throws {
        // Given
        let catalog = POSCatalog(
            products: [
                POSProduct.fake().copy(siteID: sampleSiteID, productID: 100),
                POSProduct.fake().copy(siteID: sampleSiteID, productID: 200, productTypeKey: "variable")
            ],
            variations: [
                POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 200, productVariationID: 500),
                POSProductVariation.fake().copy(siteID: sampleSiteID, productID: 200, productVariationID: 501)
            ],
            syncDate: .now
        )
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // When - Delete one product and one variation
        try await sut.deleteProducts([100], variationIDs: [500], siteID: sampleSiteID)

        // Then
        try await db.read { db in
            let products = try PersistedProduct
                .filter(sql: "\(PersistedProduct.Columns.siteID.name) = \(sampleSiteID)")
                .fetchAll(db)
            #expect(products.count == 1)
            #expect(products.first?.id == 200)

            let variations = try PersistedProductVariation
                .filter(sql: "\(PersistedProductVariation.Columns.siteID.name) = \(sampleSiteID)")
                .fetchAll(db)
            #expect(variations.count == 1)
            #expect(variations.first?.id == 501)
        }
    }

    @Test func deleteProducts_only_affects_specified_site() async throws {
        // Given - Add products for two different sites
        let site1Catalog = POSCatalog(
            products: [POSProduct.fake().copy(siteID: 100, productID: 1)],
            variations: [],
            syncDate: .now
        )
        let site2Catalog = POSCatalog(
            products: [POSProduct.fake().copy(siteID: 200, productID: 1)],
            variations: [],
            syncDate: .now
        )
        try await sut.replaceAllCatalogData(site1Catalog, siteID: 100)
        try await sut.replaceAllCatalogData(site2Catalog, siteID: 200)

        // When - Delete from site 100 only
        try await sut.deleteProducts([1], variationIDs: [], siteID: 100)

        // Then - Site 100 should have no products, site 200 should still have its product
        try await db.read { db in
            let site1Products = try PersistedProduct
                .filter(sql: "\(PersistedProduct.Columns.siteID.name) = 100")
                .fetchAll(db)
            #expect(site1Products.isEmpty)

            let site2Products = try PersistedProduct
                .filter(sql: "\(PersistedProduct.Columns.siteID.name) = 200")
                .fetchAll(db)
            #expect(site2Products.count == 1)
        }
    }

    @Test func deleteProducts_succeeds_when_product_not_found() async throws {
        // Given
        let catalog = POSCatalog(
            products: [POSProduct.fake().copy(siteID: sampleSiteID, productID: 100)],
            variations: [],
            syncDate: .now
        )
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // When - Try to delete a product that doesn't exist
        try await sut.deleteProducts([999], variationIDs: [], siteID: sampleSiteID)

        // Then - Should not throw, existing product should remain
        try await db.read { db in
            let products = try PersistedProduct
                .filter(sql: "\(PersistedProduct.Columns.siteID.name) = \(sampleSiteID)")
                .fetchAll(db)
            #expect(products.count == 1)
            #expect(products.first?.id == 100)
        }
    }

    // MARK: - FTS Index Rebuild Tests

    @Test func replaceAllCatalogData_rebuilds_fts_index() async throws {
        // Given - product with valid productTypeKey and statusKey for FTS indexing
        let product = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1, name: "Coffee Beans", productTypeKey: "simple", statusKey: "publish")
        let catalog = POSCatalog(products: [product], variations: [], syncDate: .now)

        // When
        try await sut.replaceAllCatalogData(catalog, siteID: sampleSiteID)

        // Then
        let indexCount = try await db.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM pos_search_fts WHERE siteID = ?", arguments: [sampleSiteID]) ?? 0
        }
        #expect(indexCount == 1)
    }

    @Test func persistIncrementalCatalogData_rebuilds_fts_index() async throws {
        // Given - products with valid productTypeKey and statusKey for FTS indexing
        let product1 = POSProduct.fake().copy(siteID: sampleSiteID, productID: 1, name: "Coffee", productTypeKey: "simple", statusKey: "publish")
        let initialCatalog = POSCatalog(products: [product1], variations: [], syncDate: .now)
        try await sut.replaceAllCatalogData(initialCatalog, siteID: sampleSiteID)

        // When
        let product2 = POSProduct.fake().copy(siteID: sampleSiteID, productID: 2, name: "Tea", productTypeKey: "simple", statusKey: "publish")
        let incrementalCatalog = POSCatalog(products: [product2], variations: [], syncDate: .now)
        try await sut.persistIncrementalCatalogData(incrementalCatalog, siteID: sampleSiteID)

        // Then
        let indexCount = try await db.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM pos_search_fts WHERE siteID = ?", arguments: [sampleSiteID]) ?? 0
        }
        #expect(indexCount == 2)
    }
}

private extension POSCatalogPersistenceServiceTests {
    func insertProduct(_ product: POSProduct) async throws {
        try await db.write { db in
            try PersistedSite(id: sampleSiteID).insert(db, onConflict: .ignore)
        }
        try product.save(to: db)
    }

    func insertVariation(_ variation: POSProductVariation) async throws {
        try variation.save(to: db)
    }
}
