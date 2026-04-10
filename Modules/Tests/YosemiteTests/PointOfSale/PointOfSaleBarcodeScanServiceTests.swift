import Testing
import WooFoundation
@testable import Networking
@testable import Yosemite

struct PointOfSaleBarcodeScanServiceTests {
    private var currencySettings: CurrencySettings!
    private var network: MockNetwork!
    private let siteID: Int64 = 123
    private var sut: PointOfSaleBarcodeScanService!

    init() {
        network = MockNetwork()
        currencySettings = CurrencySettings()
        sut = PointOfSaleBarcodeScanService(
            siteID: siteID,
            productsRemote: ProductsRemote(network: network),
            currencySettings: currencySettings
        )
    }

    @Test func getItem_returns_simple_product_when_found() async throws {
        // Given
        let barcode = "123456789"
        network.simulateResponse(requestUrlSuffix: "products", filename: "pos-products")

        // When
        let item = try await sut.getItem(barcode: barcode)

        // Then
        guard case let .simpleProduct(product) = item else {
            Issue.record("Expected simple product, but got \(item)")
            return
        }

        #expect(product.name == "Test Product")
        #expect(product.price == "10.00")
        #expect(product.productID == 123)
        #expect(product.manageStock == true)
        #expect(product.stockQuantity == 10)
        #expect(product.stockStatusKey == "instock")
    }

    @Test func getItem_throws_error_when_product_not_found() async throws {
        // Given
        let barcode = "nonexistent"
        network.simulateError(requestUrlSuffix: "products", error: NetworkError.notFound())

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.notFound(scannedCode: barcode)) {
            _ = try await sut.getItem(barcode: barcode)
        }
    }

    @Test func getItem_throws_notFound_when_product_has_trash_status() async throws {
        // Given
        let barcode = "123456789"
        network.simulateResponse(requestUrlSuffix: "products", filename: "pos-product-trashed")

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.notFound(scannedCode: barcode)) {
            _ = try await sut.getItem(barcode: barcode)
        }
    }

    @Test func getItem_throws_notFound_when_product_has_draft_status() async throws {
        // Given
        let barcode = "123456789"
        network.simulateResponse(requestUrlSuffix: "products", filename: "pos-product-draft")

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.notFound(scannedCode: barcode)) {
            _ = try await sut.getItem(barcode: barcode)
        }
    }
}
