import Foundation
import Testing
@testable import Storage

@Suite("PersistedProduct Barcode Query Tests")
struct PersistedProductBarcodeQueryTests {
    private let siteID: Int64 = 123
    private var grdbManager: GRDBManager!

    init() async throws {
        grdbManager = try GRDBManager()

        // Initialize site
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: siteID).insert(db)
        }
    }

    // MARK: - Global Unique ID Query Tests

    @Test("posProductByGlobalUniqueID finds product with matching global unique ID")
    func test_finds_product_by_global_unique_id() async throws {
        // Given
        let globalUniqueID = "UPC-123456"
        let product = PersistedProduct(
            id: 1,
            siteID: siteID,
            name: "Test Product",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: "SKU-001",
            globalUniqueID: globalUniqueID,
            price: "10.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        try await insertProduct(product)

        // When
        let result = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductByGlobalUniqueID(siteID: siteID, globalUniqueID: globalUniqueID).fetchOne(db)
        }

        // Then
        #expect(result != nil)
        #expect(result?.id == 1)
        #expect(result?.name == "Test Product")
        #expect(result?.globalUniqueID == globalUniqueID)
    }

    @Test("posProductByGlobalUniqueID returns nil when no match")
    func test_returns_nil_when_no_global_unique_id_match() async throws {
        // When
        let result = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductByGlobalUniqueID(siteID: siteID, globalUniqueID: "NONEXISTENT").fetchOne(db)
        }

        // Then
        #expect(result == nil)
    }

    @Test("posProductByGlobalUniqueID filters out downloadable products")
    func test_global_unique_id_query_filters_downloadable() async throws {
        // Given
        let globalUniqueID = "UPC-DOWNLOADABLE"
        let downloadableProduct = PersistedProduct(
            id: 2,
            siteID: siteID,
            name: "Downloadable Product",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: globalUniqueID,
            price: "5.00",
            downloadable: true,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        try await insertProduct(downloadableProduct)

        // When
        let result = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductByGlobalUniqueID(siteID: siteID, globalUniqueID: globalUniqueID).fetchOne(db)
        }

        // Then
        #expect(result == nil)
    }

    @Test("posProductByGlobalUniqueID filters out unsupported product types")
    func test_global_unique_id_query_filters_unsupported_types() async throws {
        // Given
        let globalUniqueID = "UPC-GROUPED"
        let groupedProduct = PersistedProduct(
            id: 3,
            siteID: siteID,
            name: "Grouped Product",
            productTypeKey: "grouped",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: globalUniqueID,
            price: "0.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        try await insertProduct(groupedProduct)

        // When
        let result = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductByGlobalUniqueID(siteID: siteID, globalUniqueID: globalUniqueID).fetchOne(db)
        }

        // Then
        #expect(result == nil)
    }

    // MARK: - SKU Query Tests

    @Test("posProductBySKU finds product with matching SKU")
    func test_finds_product_by_sku() async throws {
        // Given
        let sku = "SKU-ABC-123"
        let product = PersistedProduct(
            id: 4,
            siteID: siteID,
            name: "Product with SKU",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: sku,
            globalUniqueID: nil,
            price: "15.00",
            downloadable: false,
            parentID: 0,
            manageStock: true,
            stockQuantity: 10,
            stockStatusKey: "instock"
        )
        try await insertProduct(product)

        // When
        let result = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductBySKU(siteID: siteID, sku: sku).fetchOne(db)
        }

        // Then
        #expect(result != nil)
        #expect(result?.id == 4)
        #expect(result?.sku == sku)
    }

    @Test("posProductBySKU returns nil when no match")
    func test_returns_nil_when_no_sku_match() async throws {
        // When
        let result = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductBySKU(siteID: siteID, sku: "NONEXISTENT-SKU").fetchOne(db)
        }

        // Then
        #expect(result == nil)
    }

    @Test("posProductBySKU filters out downloadable products")
    func test_sku_query_filters_downloadable() async throws {
        // Given
        let sku = "SKU-DOWNLOADABLE"
        let downloadableProduct = PersistedProduct(
            id: 5,
            siteID: siteID,
            name: "Downloadable Product",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: sku,
            globalUniqueID: nil,
            price: "5.00",
            downloadable: true,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        try await insertProduct(downloadableProduct)

        // When
        let result = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductBySKU(siteID: siteID, sku: sku).fetchOne(db)
        }

        // Then
        #expect(result == nil)
    }

    @Test("posProductBySKU accepts variable products")
    func test_sku_query_accepts_variable_products() async throws {
        // Given
        let sku = "SKU-VARIABLE"
        let variableProduct = PersistedProduct(
            id: 6,
            siteID: siteID,
            name: "Variable Product",
            productTypeKey: "variable",
            fullDescription: nil,
            shortDescription: nil,
            sku: sku,
            globalUniqueID: nil,
            price: "0.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        try await insertProduct(variableProduct)

        // When
        let result = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductBySKU(siteID: siteID, sku: sku).fetchOne(db)
        }

        // Then
        #expect(result != nil)
        #expect(result?.productTypeKey == "variable")
    }

    // MARK: - Site Isolation Tests

    @Test("Queries only return products from specified site")
    func test_queries_respect_site_isolation() async throws {
        // Given
        let otherSiteID: Int64 = 456
        let barcode = "SHARED-BARCODE"

        // Insert site
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: otherSiteID).insert(db)
        }

        // Insert product for our site
        let ourProduct = PersistedProduct(
            id: 7,
            siteID: siteID,
            name: "Our Product",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: barcode,
            globalUniqueID: barcode,
            price: "10.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )

        // Insert product for other site
        let otherProduct = PersistedProduct(
            id: 8,
            siteID: otherSiteID,
            name: "Other Site Product",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: barcode,
            globalUniqueID: barcode,
            price: "20.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )

        try await insertProduct(ourProduct)
        try await insertProduct(otherProduct)

        // When
        let resultBySKU = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductBySKU(siteID: siteID, sku: barcode).fetchOne(db)
        }
        let resultByGlobalID = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductByGlobalUniqueID(siteID: siteID, globalUniqueID: barcode).fetchOne(db)
        }

        // Then
        #expect(resultBySKU?.siteID == siteID)
        #expect(resultBySKU?.id == 7)
        #expect(resultByGlobalID?.siteID == siteID)
        #expect(resultByGlobalID?.id == 7)
    }

    // MARK: - Helper Methods

    private func insertProduct(_ product: PersistedProduct) async throws {
        try await grdbManager.databaseConnection.write { db in
            try product.insert(db)
        }
    }
}
