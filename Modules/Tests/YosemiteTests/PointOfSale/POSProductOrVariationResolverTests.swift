import Foundation
import Testing
import WooFoundation
@testable import Yosemite
@testable import Networking

struct POSProductOrVariationResolverTests {
    private var mockProductsRemote: MockProductsRemote!
    private var mockItemMapper: MockPointOfSaleItemMapper!
    private var sut: POSProductOrVariationResolver!
    private var currencySettings: CurrencySettings!

    init() {
        mockProductsRemote = MockProductsRemote()
        mockItemMapper = MockPointOfSaleItemMapper()
        currencySettings = CurrencySettings()
        sut = POSProductOrVariationResolver(productsRemote: mockProductsRemote,
                                            currencySettings: currencySettings,
                                            itemMapper: mockItemMapper)
    }

    @Test("Resolves simple product correctly")
    func testResolvesSimpleProduct() async throws {
        // Given
        let simpleProduct = POSProduct.fake().copy(
            productID: 123,
            name: "Simple Product",
            productTypeKey: "simple",
            price: "10.00"
        )
        let expectedItem = POSItem.simpleProduct(POSSimpleProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Simple Product",
            formattedPrice: "$10.00",
            productID: 123,
            price: "10.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: ""
        ))
        mockItemMapper.mockMappedProducts = [expectedItem]
        let scannedCode = "test-barcode-simple"

        // When
        let result = try await sut.itemForProductOrVariation(simpleProduct, scannedCode: scannedCode)

        // Then
        #expect(mockItemMapper.mapProductsToPOSItemsCalled)
        #expect(mockItemMapper.mockProducts.count == 1)
        #expect(mockItemMapper.mockProducts.first?.productID == 123)
        #expect(result == expectedItem)
    }

    @Test("Resolves variation correctly")
    func testResolvesVariation() async throws {
        // Given
        let variation = POSProduct.fake().copy(
            productID: 456,
            name: "Variation",
            productTypeKey: "variation",
            price: "15.00",
            parentID: 123
        )
        let parentProduct = POSProduct.fake().copy(
            productID: 123,
            name: "Parent Product",
            productTypeKey: "variable"
        )
        let expectedParentItem = POSItem.variableParentProduct(POSVariableParentProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Parent Product",
            productImageSource: nil,
            productID: 123,
            allAttributes: []
        ))
        let expectedVariationItem = POSItem.variation(POSVariation(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Variation",
            formattedPrice: "$15.00",
            price: "15.00",
            productImageSource: nil,
            productID: 123,
            variationID: 456,
            parentProductName: "Parent Product"
        ))
        let scannedCode = "test-barcode-variation"

        mockProductsRemote.whenLoadingProductForPointOfSale(siteID: variation.siteID, productID: variation.parentID, thenReturn: .success(parentProduct))
        mockItemMapper.mockMappedProducts = [expectedParentItem]
        mockItemMapper.mockMappedVariations = [expectedVariationItem]

        // When
        let result = try await sut.itemForProductOrVariation(variation, scannedCode: scannedCode)

        // Then
        #expect(mockProductsRemote.invocationCountOfLoadPOSProduct == 1)
        #expect(mockProductsRemote.requestedProductIDsForFetchingPOSProduct.contains(variation.parentID))

        #expect(mockItemMapper.mapVariationsToPOSItemsCalled)
        #expect(mockItemMapper.mockVariations.count == 1)
        #expect(mockItemMapper.mockVariations.first?.productVariationID == 456)
        #expect(result == expectedVariationItem)
    }

    @Test("Throws unknown error for product with no mapped items")
     func testThrowsErrorForUnknownProductType() async {
         // Given
         let unknownProduct = POSProduct.fake().copy(
            productID: 321,
            productTypeKey: "simple"
         )
         mockItemMapper.mockMappedProducts = []
         let scannedCode = "test-unknown"

         // When/Then
         await #expect(throws: PointOfSaleBarcodeScanError.unknown(scannedCode: scannedCode)) {
             _ = try await sut.itemForProductOrVariation(unknownProduct, scannedCode: scannedCode)
         }
     }

    @Test("Throws error for downloadable product")
    func testThrowsErrorForDownloadableProduct() async throws {
        // Given
        let downloadableProduct = POSProduct.fake().copy(
            productID: 321,
            productTypeKey: "simple",
            downloadable: true
        )
        let scannedCode = "test-barcode-downloadable"
        let productName = downloadableProduct.name

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.downloadableProduct(scannedCode: scannedCode, productName: productName)) {
            _ = try await sut.itemForProductOrVariation(downloadableProduct, scannedCode: scannedCode)
        }

        try await #expect(queryParametersForProductsRequest().contains("downloadable=false"))
    }

    @Test("Throws error for unsupported product type")
    func testThrowsErrorForUnsupportedProductType() async throws {
        // Given
        let unsupportedProduct = POSProduct.fake().copy(
            productID: 789,
            productTypeKey: "grouped"
        )
        let scannedCode = "test-barcode-unsupported"
        let productName = unsupportedProduct.name

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.unsupportedProductType(scannedCode: scannedCode, productName: productName, productType: .grouped)) {
            _ = try await sut.itemForProductOrVariation(unsupportedProduct, scannedCode: scannedCode)
        }
        try await #expect(queryParametersForProductsRequest().contains("include_types=simple,variable"))
    }

    @Test("Throws notFound or loadingError when parent product loading fails")
    func testThrowsErrorWhenParentProductFails() async {
        // Given
        let variation = POSProduct.fake().copy(
            productID: 456,
            productTypeKey: "variation",
            parentID: 123
        )
        let scannedCode = "test-barcode-loading"
        let someError = NSError(domain: "Test", code: 1, userInfo: nil)
        let dotcomNotFoundError = DotcomError.unknown(code: "woocommerce_rest_product_invalid_id", message: "Not found", data: nil)

        // NotFound case (simulate DotcomError for not found)
        mockProductsRemote.whenLoadingProductForPointOfSale(siteID: variation.siteID, productID: variation.parentID, thenReturn: .failure(dotcomNotFoundError))
        await #expect(throws: PointOfSaleBarcodeScanError.noParentProductForVariation(scannedCode: scannedCode)) {
            _ = try await sut.itemForProductOrVariation(variation, scannedCode: scannedCode)
        }

        // LoadingError case
        mockProductsRemote.whenLoadingProductForPointOfSale(siteID: variation.siteID, productID: variation.parentID, thenReturn: .failure(someError))
        await #expect(throws: PointOfSaleBarcodeScanError.loadingError(scannedCode: scannedCode, underlyingError: someError)) {
            _ = try await sut.itemForProductOrVariation(variation, scannedCode: scannedCode)
        }
    }

    @Test("Throws mappingError when toProductVariation fails")
    func testThrowsMappingErrorWhenToProductVariationFails() async {
        // Given: attributes with empty options will cause toProductVariationAttribute to throw
        let badAttribute = ProductAttribute(siteID: 1, attributeID: 1, name: "Bad", position: 0, visible: true, variation: true, options: [])
        let variation = POSProduct.fake().copy(
            productID: 456,
            productTypeKey: "variation",
            parentID: 123,
            attributes: [badAttribute]
        )
        let scannedCode = "test-barcode-mapping"
        let error = ProductAttribute.ProductAttributeError.notFromAVariationAsAProduct

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.mappingError(scannedCode: scannedCode, underlyingError: error)) {
            _ = try await sut.itemForProductOrVariation(variation, scannedCode: scannedCode)
        }
    }

    @Test("Throws error when no parent product found for variation")
    func testThrowsErrorWhenNoParentProductFound() async {
        // Given
        let variation = POSProduct.fake().copy(
            productID: 456,
            productTypeKey: "variation",
            parentID: 0 // Invalid parent ID for a variation
        )
        let scannedCode = "test-barcode-noparent"

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.noParentProductForVariation(scannedCode: scannedCode)) {
            _ = try await sut.itemForProductOrVariation(variation, scannedCode: scannedCode)
        }
    }

    @Test("Throws error when variation cannot be converted")
    func testThrowsErrorWhenVariationCannotBeConverted() async {
        // Given
        let variation = POSProduct.fake().copy(
            productID: 456,
            productTypeKey: "variation",
            parentID: 123
        )
        let parentProduct = POSProduct.fake().copy(
            productID: 123,
            name: "Parent Product",
            productTypeKey: "simple" // Wrong type for parent
        )
        let scannedCode = "test-barcode-cannotconvert"

        mockProductsRemote.whenLoadingProductForPointOfSale(siteID: variation.siteID, productID: variation.parentID, thenReturn: .success(parentProduct))
        mockItemMapper.mockMappedProducts = []

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.variationCouldNotBeConverted(scannedCode: scannedCode)) {
            _ = try await sut.itemForProductOrVariation(variation, scannedCode: scannedCode)
        }
    }
}

// MARK: - Helpers

private extension POSProductOrVariationResolverTests {
    /// Verify that the query parameters for the POS products request include the expected parameter and match resolver logic.
    func queryParametersForProductsRequest() async throws -> [String] {
        let network = MockNetwork()
        let remote = ProductsRemote(network: network)
        _ = try? await remote.loadProductsForPointOfSale(
            for: 1,
            productTypes: PointOfSaleDefaultPurchasableItemFetchStrategy.defaultProductTypes,
            pageNumber: 1
        )
        return network.queryParameters ?? []
    }
}

// MARK: - PointOfSaleBarcodeScanError equatable for testing

extension PointOfSaleBarcodeScanError: @retroactive Equatable {
    public static func == (lhs: PointOfSaleBarcodeScanError, rhs: PointOfSaleBarcodeScanError) -> Bool {
        switch (lhs, rhs) {
        case let (.unknown(lhsScannedCode), .unknown(rhsScannedCode)):
            return lhsScannedCode == rhsScannedCode
        case let (.noParentProductForVariation(lhsScannedCode), .noParentProductForVariation(rhsScannedCode)):
            return lhsScannedCode == rhsScannedCode
        case let (.variationCouldNotBeConverted(lhsScannedCode), .variationCouldNotBeConverted(rhsScannedCode)):
            return lhsScannedCode == rhsScannedCode
        case let (.notFound(lhsScannedCode), .notFound(rhsScannedCode)):
            return lhsScannedCode == rhsScannedCode
        case let (.unsupportedProductType(lhsScannedCode, lhsProductName, _), .unsupportedProductType(rhsScannedCode, rhsProductName, _)):
            return lhsScannedCode == rhsScannedCode && lhsProductName == rhsProductName
        case let (.downloadableProduct(lhsScannedCode, lhsProductName), .downloadableProduct(rhsScannedCode, rhsProductName)):
            return lhsScannedCode == rhsScannedCode && lhsProductName == rhsProductName
        case let (.loadingError(lhsScannedCode, _), .loadingError(rhsScannedCode, _)):
            return lhsScannedCode == rhsScannedCode
        case let (.mappingError(lhsScannedCode, _), .mappingError(rhsScannedCode, _)):
            return lhsScannedCode == rhsScannedCode
        case let (.scanTooShort(lhsScannedCode), .scanTooShort(rhsScannedCode)):
            return lhsScannedCode == rhsScannedCode
        case let (.timedOut(lhsScannedCode), .timedOut(rhsScannedCode)):
            return lhsScannedCode == rhsScannedCode
        default:
            return false
        }
    }
}
