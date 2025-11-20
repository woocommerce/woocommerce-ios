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
            stockStatusKey: "instock",
            statusKey: "publish"
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
            stockStatusKey: "instock",
            statusKey: "publish"
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
            stockStatusKey: "instock",
            statusKey: "publish"
        )

        try await insertProduct(ourProduct)
        try await insertProduct(otherProduct)

        // When
        let resultByGlobalID = try await grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductByGlobalUniqueID(siteID: siteID, globalUniqueID: barcode).fetchOne(db)
        }

        // Then
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
