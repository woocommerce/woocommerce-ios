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

    @Test("Returns simple product when found by SKU")
    func test_returns_simple_product_by_sku() async throws {
        // Given
        let sku = "SKU-TEST-123"
        let product = PersistedProduct(
            id: 2,
            siteID: siteID,
            name: "Product with SKU",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: sku,
            globalUniqueID: nil,
            price: "20.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        try await insertProduct(product)

        // When
        let item = try await sut.getItem(barcode: sku)

        // Then
        guard case let .simpleProduct(posProduct) = item else {
            Issue.record("Expected simple product, got \(item)")
            return
        }
        #expect(posProduct.name == "Product with SKU")
        #expect(posProduct.productID == 2)
    }

    @Test("Prioritizes global unique ID over SKU when both match different products")
    func test_prioritizes_global_unique_id_over_sku() async throws {
        // Given
        let barcode = "SHARED-CODE"

        // Product with matching global unique ID
        let productWithGlobalID = PersistedProduct(
            id: 3,
            siteID: siteID,
            name: "Product with Global ID",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: "DIFFERENT-SKU",
            globalUniqueID: barcode,
            price: "30.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )

        // Product with matching SKU
        let productWithSKU = PersistedProduct(
            id: 4,
            siteID: siteID,
            name: "Product with SKU",
            productTypeKey: "simple",
            fullDescription: nil,
            shortDescription: nil,
            sku: barcode,
            globalUniqueID: "DIFFERENT-GLOBAL-ID",
            price: "40.00",
            downloadable: false,
            parentID: 0,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )

        try await insertProduct(productWithGlobalID)
        try await insertProduct(productWithSKU)

        // When
        let item = try await sut.getItem(barcode: barcode)

        // Then
        guard case let .simpleProduct(posProduct) = item else {
            Issue.record("Expected simple product, got \(item)")
            return
        }
        // Should find the one with matching global ID first
        #expect(posProduct.name == "Product with Global ID")
        #expect(posProduct.productID == 3)
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

    @Test("Returns variation when found by SKU")
    func test_returns_variation_by_sku() async throws {
        // Given
        let sku = "VAR-SKU-456"

        // Insert parent product
        let parentProduct = PersistedProduct(
            id: 11,
            siteID: siteID,
            name: "Another Variable Parent",
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
            id: 110,
            siteID: siteID,
            productID: 11,
            sku: sku,
            globalUniqueID: nil,
            price: "25.00",
            downloadable: false,
            fullDescription: nil,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        )
        try await insertVariation(variation)

        // When
        let item = try await sut.getItem(barcode: sku)

        // Then
        guard case let .variation(variationItem) = item else {
            Issue.record("Expected variation, got \(item)")
            return
        }
        #expect(variationItem.productVariationID == 110)
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
        await #expect(throws: PointOfSaleBarcodeScanError.notFound(scannedCode: barcode)) {
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
        await #expect(throws: PointOfSaleBarcodeScanError.notFound(scannedCode: barcode)) {
            _ = try await sut.getItem(barcode: barcode)
        }
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
