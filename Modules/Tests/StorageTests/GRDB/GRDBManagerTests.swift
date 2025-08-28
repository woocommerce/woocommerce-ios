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
            let tableExists = try manager.databaseQueue.read { db in
                return (
                    try db.tableExists("product"),
                    try db.tableExists("productAttribute"),
                    try db.tableExists("productImage"),
                    try db.tableExists("productVariation"),
                    try db.tableExists("productVariationAttribute"),
                    try db.tableExists("productVariationImage")
                )
            }

            // Then
            #expect(tableExists.0, "product table should exist")
            #expect(tableExists.1, "productAttribute table should exist")
            #expect(tableExists.2, "productImage table should exist")
            #expect(tableExists.3, "productVariation table should exist")
            #expect(tableExists.4, "productVariationAttribute table should exist")
            #expect(tableExists.5, "productVariationImage table should exist")
        }
    }

    // MARK: - CRUD Tests

    struct CRUDTests {
        @Test("Can insert product to a freshly initialised database")
        func test_after_init_can_insert_a_product() throws {
            // Given
            let manager = try GRDBManager()

            // When
            try manager.databaseQueue.write { db in
                let record = TestProduct(
                    siteID: 1,
                    productID: 100,
                    name: "Test Product",
                    productTypeKey: "simple",
                    price: "10.00",
                    downloadable: false,
                    parentID: 0
                )
                try record.insert(db)
            }

            // Then
            let productCount = try manager.databaseQueue.read { db in
                try TestProduct.fetchCount(db)
            }

            #expect(productCount == 1)
        }

        @Test("Can insert product variation with a relationship to a product")
        func test_after_init_can_insert_productVariation_with_foreign_key() throws {
            // Given
            let manager = try GRDBManager()

            // Insert parent product
            try manager.databaseQueue.write { db in
                let product = TestProduct(
                    siteID: 1,
                    productID: 100,
                    name: "Variable Product",
                    productTypeKey: "variable",
                    price: "10.00",
                    downloadable: false,
                    parentID: 0
                )
                try product.insert(db)
            }

            // When - Insert variation
            try manager.databaseQueue.write { db in
                let variation = TestProductVariation(
                    siteID: 1,
                    productVariationID: 200,
                    productID: 100,
                    price: "12.00",
                    downloadable: false
                )
                try variation.insert(db)
            }

            // Then
            let variations = try manager.databaseQueue.read { db in
                try TestProductVariation.fetchAll(db)
            }

            #expect(variations.count == 1)
            #expect(variations.first?.productID == 100)
        }

        @Test("Can query variations by product ID")
        func test_after_init_and_insert_can_query_productVariation_using_foreign_key() throws {
            // Given
            let manager = try GRDBManager()

            try manager.databaseQueue.write { db in
                // Insert product
                let product = TestProduct(
                    siteID: 1,
                    productID: 100,
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
                        productVariationID: Int64(200 + i),
                        productID: 100,
                        price: "\(10 + i).00",
                        downloadable: false
                    )
                    try variation.insert(db)
                }
            }

            // When
            let variations = try manager.databaseQueue.read { db in
                try TestProductVariation
                    .filter(Column("productID") == 100)
                    .fetchAll(db)
            }

            // Then
            #expect(variations.count == 3)
            #expect(variations.allSatisfy { $0.productID == 100 })
        }

        @Test("Can insert product attribute with options array (JSON)")
        func test_after_init_can_insert_productAttribute_with_options_as_JSON_array() throws {
            // Given
            let manager = try GRDBManager()

            try manager.databaseQueue.write { db in
                // Insert product first
                let product = TestProduct(
                    siteID: 1,
                    productID: 100,
                    name: "Test Product",
                    productTypeKey: "simple",
                    price: "10.00",
                    downloadable: false,
                    parentID: 0
                )
                try product.insert(db)
            }

            // When
            try manager.databaseQueue.write { db in
                let attribute = TestProductAttribute(
                    siteID: 1,
                    attributeID: 1,
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
            let attribute = try manager.databaseQueue.read { db in
                try TestProductAttribute.fetchOne(db)
            }

            #expect(attribute != nil)
            #expect(attribute?.options == ["Red", "Blue", "Green"])
        }

        @Test("Can insert variation attributes")
        func test_after_init_can_insert_variation_attributes() throws {
            // Given
            let manager = try GRDBManager()

            try manager.databaseQueue.write { db in
                // Insert product
                let product = TestProduct(
                    siteID: 1,
                    productID: 100,
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
                    productVariationID: 200,
                    productID: 100,
                    price: "12.00",
                    downloadable: false
                )
                try variation.insert(db)
            }

            // When
            try manager.databaseQueue.write { db in
                let variationAttribute = TestProductVariationAttribute(
                    siteID: 1,
                    productVariationID: 200,
                    attributeID: 1,
                    name: "Color",
                    option: "Red"
                )
                try variationAttribute.insert(db)
            }

            // Then
            let attributes = try manager.databaseQueue.read { db in
                try TestProductVariationAttribute.fetchAll(db)
            }

            #expect(attributes.count == 1)
            #expect(attributes.first?.option == "Red")
        }
    }
}

// MARK: - Test Models

struct TestProduct: Codable {
    let siteID: Int64
    let productID: Int64
    let name: String
    let productTypeKey: String
    let fullDescription: String?
    let shortDescription: String?
    let sku: String?
    let globalUniqueID: String?
    let price: String
    let downloadable: Bool
    let parentID: Int64

    init(siteID: Int64, productID: Int64, name: String, productTypeKey: String,
         price: String, downloadable: Bool, parentID: Int64,
         fullDescription: String? = nil, shortDescription: String? = nil,
         sku: String? = nil, globalUniqueID: String? = nil) {
        self.siteID = siteID
        self.productID = productID
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
    let productVariationID: Int64
    let productID: Int64
    let sku: String?
    let globalUniqueID: String?
    let price: String
    let downloadable: Bool
    let description: String?

    init(siteID: Int64, productVariationID: Int64, productID: Int64,
         price: String, downloadable: Bool,
         sku: String? = nil, globalUniqueID: String? = nil, description: String? = nil) {
        self.siteID = siteID
        self.productVariationID = productVariationID
        self.productID = productID
        self.price = price
        self.downloadable = downloadable
        self.sku = sku
        self.globalUniqueID = globalUniqueID
        self.description = description
    }
}

extension TestProductVariation: FetchableRecord, PersistableRecord {
    static let databaseTableName = "productVariation"
}

struct TestProductAttribute: Codable {
    let siteID: Int64
    let attributeID: Int64
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
    let siteID: Int64
    let productVariationID: Int64
    let attributeID: Int64
    let name: String
    let option: String
}

extension TestProductVariationAttribute: FetchableRecord, PersistableRecord {
    static let databaseTableName = "productVariationAttribute"
}
