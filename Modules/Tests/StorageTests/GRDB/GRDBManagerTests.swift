import Testing
import GRDB
@testable import Storage

struct GRDBManagerTests {

    // MARK: - Migration Tests
    struct MigrationTests {
        @Test("Migration runs successfully on initialisation")
        func test_init_full_migration_runs_successfully() throws {
            // Should not throw – initialisation performs migrations
            _ = try GRDBManager()
        }

        @Test("All tables are created on initialisation")
        func test_init_all_tables_are_created() throws {
            // Given
            let manager = try GRDBManager()

            // When
            let tableExists = try manager.databaseConnection.read { db in
                return (
                    try db.tableExists("site"),
                    try db.tableExists("product"),
                    try db.tableExists("productAttribute"),
                    try db.tableExists("productImage"),
                    try db.tableExists("productVariation"),
                    try db.tableExists("productVariationAttribute"),
                    try db.tableExists("productVariationImage")
                )
            }

            // Then
            #expect(tableExists.0, "site table should exist")
            #expect(tableExists.1, "product table should exist")
            #expect(tableExists.2, "productAttribute table should exist")
            #expect(tableExists.3, "productImage table should exist")
            #expect(tableExists.4, "productVariation table should exist")
            #expect(tableExists.5, "productVariationAttribute table should exist")
            #expect(tableExists.6, "productVariationImage table should exist")
        }
    }

    // MARK: - CRUD Tests

    struct CRUDTests {
        let manager: GRDBManager
        let sampleSiteID: Int64 = 1

        init() throws {
            self.manager = try GRDBManager()
            try manager.databaseConnection.write { db in
                let record = TestSite(id: sampleSiteID)
                try record.insert(db)
            }
        }

        @Test("Insert product to a freshly initialised database")
        func test_after_init_can_insert_a_product() throws {
            // Given

            // When
            try manager.databaseConnection.write { db in
                let record = TestProduct(
                    siteID: 1,
                    id: 100,
                    name: "Test Product",
                    productTypeKey: "simple",
                    price: "10.00",
                    downloadable: false,
                    parentID: 0
                )
                try record.insert(db)
            }

            // Then
            let productCount = try manager.databaseConnection.read { db in
                try TestProduct.fetchCount(db)
            }

            #expect(productCount == 1)
        }

        @Test("Insert product variation with a relationship to a product")
        func test_after_init_can_insert_productVariation_with_foreign_key() throws {
            // Given – parent product
            try manager.databaseConnection.write { db in
                let product = TestProduct(
                    siteID: 1,
                    id: 100,
                    name: "Variable Product",
                    productTypeKey: "variable",
                    price: "10.00",
                    downloadable: false,
                    parentID: 0
                )
                try product.insert(db)
            }

            // When - Insert variation
            try manager.databaseConnection.write { db in
                let variation = TestProductVariation(
                    siteID: 1,
                    id: 200,
                    productID: 100,
                    price: "12.00",
                    downloadable: false
                )
                try variation.insert(db)
            }

            // Then
            let variations = try manager.databaseConnection.read { db in
                try TestProductVariation.fetchAll(db)
            }

            #expect(variations.count == 1)
            #expect(variations.first?.productID == 100)
        }

        @Test("Fetch variations by product ID")
        func test_after_init_and_insert_can_query_productVariation_using_foreign_key() throws {
            // Given parent product and some variations
            try manager.databaseConnection.write { db in
                // Insert product
                let product = TestProduct(
                    siteID: 1,
                    id: 100,
                    name: "Variable Product",
                    productTypeKey: "variable",
                    price: "10.00",
                    downloadable: false,
                    parentID: 0
                )
                try product.insert(db)

                // Insert multiple variations
                for i in 1...3 {
                    let variation = TestProductVariation(
                        siteID: 1,
                        id: Int64(200 + i),
                        productID: 100,
                        price: "\(10 + i).00",
                        downloadable: false
                    )
                    try variation.insert(db)
                }
            }

            // When
            let variations = try manager.databaseConnection.read { db in
                try TestProductVariation
                    .filter(Column("productID") == 100)
                    .fetchAll(db)
            }

            // Then
            #expect(variations.count == 3)
            #expect(variations.allSatisfy { $0.productID == 100 })
        }

        @Test("Insert product attribute with options array (JSON)")
        func test_after_init_can_insert_productAttribute_with_options_as_JSON_array() throws {
            // Given parent product
            try manager.databaseConnection.write { db in
                // Insert product first
                let product = TestProduct(
                    siteID: 1,
                    id: 100,
                    name: "Test Product",
                    productTypeKey: "simple",
                    price: "10.00",
                    downloadable: false,
                    parentID: 0
                )
                try product.insert(db)
            }

            // When
            try manager.databaseConnection.write { db in
                let attribute = TestProductAttribute(
                    productID: 100,
                    name: "Color",
                    position: 0,
                    visible: true,
                    variation: true,
                    options: ["Red", "Blue", "Green"]
                )
                try attribute.insert(db)
            }

            // Then
            let attribute = try manager.databaseConnection.read { db in
                try TestProductAttribute.fetchOne(db)
            }

            #expect(attribute != nil)
            #expect(attribute?.options == ["Red", "Blue", "Green"])
        }

        @Test("Insert variation attributes")
        func test_after_init_can_insert_variation_attributes() throws {
            // Given parent product and variation
            try manager.databaseConnection.write { db in
                // Insert product
                let product = TestProduct(
                    siteID: 1,
                    id: 100,
                    name: "Variable Product",
                    productTypeKey: "variable",
                    price: "10.00",
                    downloadable: false,
                    parentID: 0
                )
                try product.insert(db)

                // Insert variation
                let variation = TestProductVariation(
                    siteID: 1,
                    id: 200,
                    productID: 100,
                    price: "12.00",
                    downloadable: false
                )
                try variation.insert(db)
            }

            // When
            try manager.databaseConnection.write { db in
                let variationAttribute = TestProductVariationAttribute(
                    productVariationID: 200,
                    name: "Color",
                    option: "Red"
                )
                try variationAttribute.insert(db)
            }

            // Then
            let attributes = try manager.databaseConnection.read { db in
                try TestProductVariationAttribute.fetchAll(db)
            }

            #expect(attributes.count == 1)
            #expect(attributes.first?.option == "Red")
        }

        @Test("Deleting site cascades to all related entities")
        func test_deleting_site_cascades_to_all_related_entities() throws {
            // Given - Create a separate site for this test to avoid interfering with other tests
            let testSiteId = try manager.databaseConnection.write { db -> Int64 in
                let site = TestSite(id: 999)
                try site.insert(db)
                return 999
            }

            // Insert full entity hierarchy
            try manager.databaseConnection.write { db in
                let product = TestProduct(
                    siteID: testSiteId,
                    id: 100,
                    name: "Test Product",
                    productTypeKey: "simple",
                    price: "10.00",
                    downloadable: false,
                    parentID: 0
                )
                try product.insert(db)

                let variation = TestProductVariation(
                    siteID: testSiteId,
                    id: 200,
                    productID: 100,
                    price: "12.00",
                    downloadable: false
                )
                try variation.insert(db)

                let productAttribute = TestProductAttribute(
                    productID: 100,
                    name: "Color",
                    position: 0,
                    visible: true,
                    variation: true,
                    options: ["Red", "Blue"]
                )
                try productAttribute.insert(db)

                let variationAttribute = TestProductVariationAttribute(
                    productVariationID: 200,
                    name: "Size",
                    option: "Large"
                )
                try variationAttribute.insert(db)
            }

            // Verify entities exist for test site
            let countsBefore = try manager.databaseConnection.read { db in
                return (
                    products: try TestProduct.filter(Column("siteID") == testSiteId).fetchCount(db),
                    variations: try TestProductVariation.filter(Column("siteID") == testSiteId).fetchCount(db),
                    productAttributes: try TestProductAttribute.filter(Column("productID") == 100).fetchCount(db),
                    variationAttributes: try TestProductVariationAttribute.filter(Column("productVariationID") == 200).fetchCount(db)
                )
            }

            #expect(countsBefore.products == 1)
            #expect(countsBefore.variations == 1)
            #expect(countsBefore.productAttributes == 1)
            #expect(countsBefore.variationAttributes == 1)

            // When - Delete the site
            _ = try manager.databaseConnection.write { db in
                try TestSite.filter(Column("id") == testSiteId).deleteAll(db)
            }

            // Then - All related entities should be deleted
            let countsAfter = try manager.databaseConnection.read { db in
                return (
                    sites: try TestSite.filter(Column("id") == testSiteId).fetchCount(db),
                    products: try TestProduct.filter(Column("siteID") == testSiteId).fetchCount(db),
                    variations: try TestProductVariation.filter(Column("siteID") == testSiteId).fetchCount(db),
                    productAttributes: try TestProductAttribute.filter(Column("productID") == 100).fetchCount(db),
                    variationAttributes: try TestProductVariationAttribute.filter(Column("productVariationID") == 200).fetchCount(db)
                )
            }

            #expect(countsAfter.sites == 0)
            #expect(countsAfter.products == 0)
            #expect(countsAfter.variations == 0)
            #expect(countsAfter.productAttributes == 0)
            #expect(countsAfter.variationAttributes == 0)
        }

        @Test("Fetch products by site")
        func test_can_fetch_products_by_site() throws {
            // Given - Create second site and products for both sites
            let site2Id = try manager.databaseConnection.write { db -> Int64 in
                let site = TestSite(id: 2)
                try site.insert(db)
                return 2
            }

            try manager.databaseConnection.write { db in
                // Site 1 products
                for i in 1...3 {
                    let product = TestProduct(
                        siteID: sampleSiteID,
                        id: Int64(i),
                        name: "Site 1 Product \(i)",
                        productTypeKey: "simple",
                        price: "\(i * 10).00",
                        downloadable: false,
                        parentID: 0
                    )
                    try product.insert(db)
                }

                // Site 2 products
                for i in 1...2 {
                    let product = TestProduct(
                        siteID: site2Id,
                        id: Int64(10 + i),
                        name: "Site 2 Product \(i)",
                        productTypeKey: "variable",
                        price: "\(i * 5).00",
                        downloadable: true,
                        parentID: 0
                    )
                    try product.insert(db)
                }
            }

            // When
            let site1Products = try manager.databaseConnection.read { db in
                try TestProduct
                    .filter(Column("siteID") == sampleSiteID)
                    .fetchAll(db)
            }

            let site2Products = try manager.databaseConnection.read { db in
                try TestProduct
                    .filter(Column("siteID") == site2Id)
                    .fetchAll(db)
            }

            // Then
            #expect(site1Products.count == 3)
            #expect(site2Products.count == 2)

            #expect(site1Products.allSatisfy { $0.siteID == sampleSiteID })
            #expect(site2Products.allSatisfy { $0.siteID == site2Id })

            #expect(site1Products.allSatisfy { $0.name.contains("Site 1") })
            #expect(site2Products.allSatisfy { $0.name.contains("Site 2") })
        }

        @Test("Fetch variations by site")
        func test_can_fetch_variations_by_site() throws {
            // Given - Product and variations
            try manager.databaseConnection.write { db in
                let product = TestProduct(
                    siteID: sampleSiteID,
                    id: 100,
                    name: "Variable Product",
                    productTypeKey: "variable",
                    price: "10.00",
                    downloadable: false,
                    parentID: 0
                )
                try product.insert(db)

                for i in 1...4 {
                    let variation = TestProductVariation(
                        siteID: sampleSiteID,
                        id: Int64(200 + i),
                        productID: 100,
                        price: "\(10 + i).00",
                        downloadable: false
                    )
                    try variation.insert(db)
                }
            }

            // When
            let variations = try manager.databaseConnection.read { db in
                try TestProductVariation
                    .filter(Column("siteID") == sampleSiteID)
                    .fetchAll(db)
            }

            // Then
            #expect(variations.count == 4)
            #expect(variations.allSatisfy { $0.siteID == sampleSiteID })
            #expect(variations.allSatisfy { $0.productID == 100 })
        }

        @Test("Cannot insert product without valid site")
        func test_cannot_insert_product_without_valid_site() throws {
            // When/Then
            #expect(throws: DatabaseError.self) {
                try manager.databaseConnection.write { db in
                    let product = TestProduct(
                        siteID: 999, // Non-existent site
                        id: 100,
                        name: "Orphaned Product",
                        productTypeKey: "simple",
                        price: "10.00",
                        downloadable: false,
                        parentID: 0
                    )
                    try product.insert(db)
                }
            }
        }

        @Test("Cannot insert variation without valid product")
        func test_cannot_insert_variation_without_valid_product() throws {
            // When/Then
            #expect(throws: DatabaseError.self) {
                try manager.databaseConnection.write { db in
                    let variation = TestProductVariation(
                        siteID: sampleSiteID,
                        id: 200,
                        productID: 999, // Non-existent product
                        price: "12.00",
                        downloadable: false
                    )
                    try variation.insert(db)
                }
            }
        }
    }
}

// MARK: - Test Models

struct TestSite: Codable {
    let id: Int64
}

extension TestSite: FetchableRecord, PersistableRecord {
    static let databaseTableName = "site"
}

struct TestProduct: Codable {
    let siteID: Int64
    let id: Int64
    let name: String
    let productTypeKey: String
    let fullDescription: String?
    let shortDescription: String?
    let sku: String?
    let globalUniqueID: String?
    let price: String
    let downloadable: Bool
    let parentID: Int64

    init(siteID: Int64, id: Int64, name: String, productTypeKey: String,
         price: String, downloadable: Bool, parentID: Int64,
         fullDescription: String? = nil, shortDescription: String? = nil,
         sku: String? = nil, globalUniqueID: String? = nil) {
        self.siteID = siteID
        self.id = id
        self.name = name
        self.productTypeKey = productTypeKey
        self.price = price
        self.downloadable = downloadable
        self.parentID = parentID
        self.fullDescription = fullDescription
        self.shortDescription = shortDescription
        self.sku = sku
        self.globalUniqueID = globalUniqueID
    }
}

extension TestProduct: FetchableRecord, PersistableRecord {
    static let databaseTableName = "product"
}

struct TestProductVariation: Codable {
    let siteID: Int64
    let id: Int64
    let productID: Int64
    let sku: String?
    let globalUniqueID: String?
    let price: String
    let downloadable: Bool
    let fullDescription: String?

    init(siteID: Int64, id: Int64, productID: Int64,
         price: String, downloadable: Bool,
         sku: String? = nil, globalUniqueID: String? = nil, fullDescription: String? = nil) {
        self.siteID = siteID
        self.id = id
        self.productID = productID
        self.price = price
        self.downloadable = downloadable
        self.sku = sku
        self.globalUniqueID = globalUniqueID
        self.fullDescription = fullDescription
    }
}

extension TestProductVariation: FetchableRecord, PersistableRecord {
    static let databaseTableName = "productVariation"
}

struct TestProductAttribute: Codable {
    let productID: Int64
    let name: String
    let position: Int
    let visible: Bool
    let variation: Bool
    let options: [String]
}

extension TestProductAttribute: FetchableRecord, PersistableRecord {
    static let databaseTableName = "productAttribute"
}

struct TestProductVariationAttribute: Codable {
    let productVariationID: Int64
    let name: String
    let option: String
}

extension TestProductVariationAttribute: FetchableRecord, PersistableRecord {
    static let databaseTableName = "productVariationAttribute"
}
