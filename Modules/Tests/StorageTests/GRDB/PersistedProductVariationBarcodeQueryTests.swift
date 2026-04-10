import Foundation
import Testing
@testable import Storage

@Suite("PersistedProductVariation Barcode Query Tests")
struct PersistedProductVariationBarcodeQueryTests {
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

    @Test("posVariationByGlobalUniqueID finds variation with matching global unique ID")
    func test_finds_variation_by_global_unique_id() async throws {
        // Given
        let globalUniqueID = "VAR-UPC-789"

        // Insert parent product first (required by foreign key)
        let parentProduct = PersistedProduct(
            id: 10,
            siteID: siteID,
            name: "Parent Product",
            productTypeKey: "variable",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: nil,
            price: "0.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        try await insertProduct(parentProduct)

        let variation = PersistedProductVariation(
            id: 100,
            siteID: siteID,
            productID: 10,
            sku: "VAR-SKU-001",
            globalUniqueID: globalUniqueID,
            price: "12.50",
            downloadable: false,
            fullDescription: nil,
            manageStock: true,
            stockQuantity: 5,
            stockStatusKey: "instock"
        )
        try await insertVariation(variation)

        // When
        let result = try await grdbManager.databaseConnection.read { db in
            try PersistedProductVariation.posVariationByGlobalUniqueID(siteID: siteID, globalUniqueID: globalUniqueID).fetchOne(db)
        }

        // Then
        #expect(result != nil)
        #expect(result?.id == 100)
        #expect(result?.globalUniqueID == globalUniqueID)
        #expect(result?.price == "12.50")
    }

    @Test("posVariationByGlobalUniqueID returns nil when no match")
    func test_returns_nil_when_no_global_unique_id_match() async throws {
        // When
        let result = try await grdbManager.databaseConnection.read { db in
            try PersistedProductVariation.posVariationByGlobalUniqueID(siteID: siteID, globalUniqueID: "NONEXISTENT").fetchOne(db)
        }

        // Then
        #expect(result == nil)
    }

    // MARK: - Site Isolation Tests

    @Test("Queries only return variations from specified site")
    func test_queries_respect_site_isolation() async throws {
        // Given
        let otherSiteID: Int64 = 456
        let barcode = "SHARED-VAR-BARCODE"

        // Insert other site
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: otherSiteID).insert(db)
        }

        // Insert parent products for both sites
        let ourParentProduct = PersistedProduct(
            id: 10,
            siteID: siteID,
            name: "Our Parent",
            productTypeKey: "variable",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: nil,
            price: "0.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        let otherParentProduct = PersistedProduct(
            id: 20,
            siteID: otherSiteID,
            name: "Other Parent",
            productTypeKey: "variable",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: nil,
            price: "0.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        try await insertProduct(ourParentProduct)
        try await insertProduct(otherParentProduct)

        // Insert variation for our site
        let ourVariation = PersistedProductVariation(
            id: 104,
            siteID: siteID,
            productID: 10,
            sku: barcode,
            globalUniqueID: barcode,
            price: "10.00",
            downloadable: false,
            fullDescription: nil,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )

        // Insert variation for other site
        let otherVariation = PersistedProductVariation(
            id: 105,
            siteID: otherSiteID,
            productID: 20,
            sku: barcode,
            globalUniqueID: barcode,
            price: "20.00",
            downloadable: false,
            fullDescription: nil,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )

        try await insertVariation(ourVariation)
        try await insertVariation(otherVariation)

        // When
        let resultByGlobalID = try await grdbManager.databaseConnection.read { db in
            try PersistedProductVariation.posVariationByGlobalUniqueID(siteID: siteID, globalUniqueID: barcode).fetchOne(db)
        }

        // Then
        #expect(resultByGlobalID?.siteID == siteID)
        #expect(resultByGlobalID?.id == 104)
    }

    // MARK: - Parent Product Relationship Test

    @Test("Can fetch variation with parent product using relationship")
    func test_fetch_variation_with_parent_product() async throws {
        // Given
        let parentProduct = PersistedProduct(
            id: 50,
            siteID: siteID,
            name: "Parent Variable Product",
            productTypeKey: "variable",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: nil,
            price: "0.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock",
            statusKey: "publish"
        )
        try await insertProduct(parentProduct)

        let variation = PersistedProductVariation(
            id: 500,
            siteID: siteID,
            productID: 50,
            sku: "TEST-VAR",
            globalUniqueID: "TEST-GLOBAL",
            price: "15.00",
            downloadable: false,
            fullDescription: nil,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        try await insertVariation(variation)

        // When
        let result: (PersistedProductVariation, PersistedProduct?)? = try await grdbManager.databaseConnection.read { db in
            guard let variation = try PersistedProductVariation.posVariationByGlobalUniqueID(siteID: siteID, globalUniqueID: "TEST-GLOBAL").fetchOne(db) else {
                return nil
            }
            let parentProduct = try variation.request(for: PersistedProductVariation.parentProduct).fetchOne(db)
            return (variation, parentProduct)
        }

        // Then
        #expect(result != nil)
        #expect(result?.0.id == 500)
        #expect(result?.1?.id == 50)
        #expect(result?.1?.name == "Parent Variable Product")
    }

    // MARK: - Helper Methods

    private func insertVariation(_ variation: PersistedProductVariation) async throws {
        try await grdbManager.databaseConnection.write { db in
            try variation.insert(db)
        }
    }

    private func insertProduct(_ product: PersistedProduct) async throws {
        try await grdbManager.databaseConnection.write { db in
            try product.insert(db)
        }
    }
}
