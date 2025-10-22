import Foundation
import Testing
import WooFoundation
@testable import Storage
@testable import Yosemite

@Suite("PointOfSaleLocalBarcodeScanService Tests")
struct PointOfSaleLocalBarcodeScanServiceTests {
    private let siteID: Int64 = 123
    private var grdbManager: GRDBManager!
    private var sut: PointOfSaleLocalBarcodeScanService!

    init() async throws {
        grdbManager = try GRDBManager()

        // Initialize site
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: siteID).insert(db)
        }

        sut = PointOfSaleLocalBarcodeScanService(
            siteID: siteID,
            grdbManager: grdbManager,
            currencySettings: CurrencySettings()
        )
    }

    // MARK: - Simple Product Tests

    @Test("Returns simple product when found by global unique ID")
    func test_returns_simple_product_by_global_unique_id() async throws {
        // Given
        let barcode = "1234567890"
        let product = PersistedProduct(
            id: 1,
            siteID: siteID,
            name: "Test Product",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: "SKU123",
            globalUniqueID: barcode,
            price: "10.00",
            downloadable: false,
            parentID: 0,
            manageStock: true,
            stockQuantity: 10,
            stockStatusKey: "instock"
        )
        try await insertProduct(product)

        // When
        let item = try await sut.getItem(barcode: barcode)

        // Then
        guard case let .simpleProduct(posProduct) = item else {
            Issue.record("Expected simple product, got \(item)")
            return
        }
        #expect(posProduct.name == "Test Product")
        #expect(posProduct.price == "10.00")
        #expect(posProduct.productID == 1)
    }

    // MARK: - Variation Tests

    @Test("Returns variation when found by global unique ID")
    func test_returns_variation_by_global_unique_id() async throws {
        // Given
        let barcode = "VAR-9876543210"

        // Insert parent product
        let parentProduct = PersistedProduct(
            id: 10,
            siteID: siteID,
            name: "Variable Parent",
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
            stockStatusKey: "instock"
        )
        try await insertProduct(parentProduct)

        // Insert variation
        let variation = PersistedProductVariation(
            id: 100,
            siteID: siteID,
            productID: 10,
            sku: "VAR-SKU",
            globalUniqueID: barcode,
            price: "15.00",
            downloadable: false,
            fullDescription: nil,
            manageStock: true,
            stockQuantity: 5,
            stockStatusKey: "instock"
        )
        try await insertVariation(variation)

        // When
        let item = try await sut.getItem(barcode: barcode)

        // Then
        guard case let .variation(variationItem) = item else {
            Issue.record("Expected variation, got \(item)")
            return
        }
        #expect(variationItem.productVariationID == 100)
        #expect(variationItem.price == "15.00")
        #expect(variationItem.parentProductName == "Variable Parent")
        #expect(variationItem.productID == 10)
    }

    // MARK: - Error Tests

    @Test("Throws notFound when barcode doesn't match any product or variation")
    func test_throws_not_found_when_no_match() async throws {
        // Given
        let barcode = "NONEXISTENT-BARCODE"

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.notFound(scannedCode: barcode)) {
            _ = try await sut.getItem(barcode: barcode)
        }
    }

    @Test("Filters out downloadable products")
    func test_filters_out_downloadable_products() async throws {
        // Given
        let barcode = "DOWNLOADABLE-123"
        let downloadableProduct = PersistedProduct(
            id: 20,
            siteID: siteID,
            name: "Downloadable Product",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: barcode,
            price: "10.00",
            downloadable: true,  // Downloadable
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        try await insertProduct(downloadableProduct)

        // When/Then - Should not find the downloadable product
        await #expect(throws: PointOfSaleBarcodeScanError.downloadableProduct(scannedCode: barcode, productName: "Downloadable Product")) {
            _ = try await sut.getItem(barcode: barcode)
        }
    }

    @Test("Filters out unsupported product types")
    func test_filters_out_unsupported_product_types() async throws {
        // Given
        let barcode = "GROUPED-123"
        let groupedProduct = PersistedProduct(
            id: 21,
            siteID: siteID,
            name: "Grouped Product",
            productTypeKey: "grouped",  // Unsupported type
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: barcode,
            price: "0.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        try await insertProduct(groupedProduct)

        // When/Then - Should not find unsupported product type
        await #expect(throws: PointOfSaleBarcodeScanError.unsupportedProductType(scannedCode: barcode,
                                                                                 productName: "Grouped Product",
                                                                                 productType: .grouped)) {
            _ = try await sut.getItem(barcode: barcode)
        }
    }

    @Test("Throws unsupportedProductType when scanning variable parent product barcode")
    func test_throws_unsupported_product_type_for_variable_parent() async throws {
        // Given
        let barcode = "VARIABLE-PARENT-123"
        let variableParentProduct = PersistedProduct(
            id: 22,
            siteID: siteID,
            name: "Variable Parent Product",
            productTypeKey: "variable",  // Variable parent cannot be added to cart
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            globalUniqueID: barcode,
            price: "0.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        try await insertProduct(variableParentProduct)

        // When/Then - Should throw unsupportedProductType error
        await #expect(throws: PointOfSaleBarcodeScanError.unsupportedProductType(scannedCode: barcode,
                                                                                 productName: "Variable Parent Product",
                                                                                 productType: .variable)) {
            _ = try await sut.getItem(barcode: barcode)
        }
    }

    @Test("Foreign key constraint prevents orphaned variations")
    func test_variations_cannot_be_orphaned() async throws {
        // Given
        let barcode = "ORPHAN-VAR-123"

        // Insert a parent product
        let parentProduct = PersistedProduct(
            id: 888,
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
            stockStatusKey: "instock"
        )
        try await insertProduct(parentProduct)

        // Insert the variation
        let variation = PersistedProductVariation(
            id: 999,
            siteID: siteID,
            productID: 888,
            sku: nil,
            globalUniqueID: barcode,
            price: "20.00",
            downloadable: false,
            fullDescription: nil,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        try await insertVariation(variation)

        // Verify the variation exists
        let variationExists = try await grdbManager.databaseConnection.read { db in
            try PersistedProductVariation.fetchOne(db, key: ["siteID": siteID, "id": 999]) != nil
        }
        #expect(variationExists, "Variation should exist after insertion")

        // When - Delete the parent product (with foreign keys enabled)
        try await grdbManager.databaseConnection.write { db in
            try db.execute(sql: "DELETE FROM product WHERE id = ? AND siteID = ?", arguments: [888, siteID])
        }

        // Then - Variation should be automatically deleted by CASCADE
        let variationStillExists = try await grdbManager.databaseConnection.read { db in
            try PersistedProductVariation.fetchOne(db, key: ["siteID": siteID, "id": 999]) != nil
        }
        #expect(!variationStillExists, "Variation should be automatically deleted by CASCADE when parent is deleted")

        // This means the noParentProductForVariation error is defensive code that won't be triggered
        // in normal operation due to foreign key constraints with CASCADE delete
    }

    // MARK: - Helper Methods

    private func insertProduct(_ product: PersistedProduct) async throws {
        try await grdbManager.databaseConnection.write { db in
            try product.insert(db)
        }
    }

    private func insertVariation(_ variation: PersistedProductVariation) async throws {
        try await grdbManager.databaseConnection.write { db in
            try variation.insert(db)
        }
    }
}
