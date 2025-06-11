import Testing
import WooFoundation
@testable import Yosemite

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
            id: UUID(),
            name: "Simple Product",
            formattedPrice: "$10.00",
            productID: 123,
            price: "10.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: ""
        ))
        mockItemMapper.mockMappedProducts = [expectedItem]

        // When
        let result = try await sut.itemForProductOrVariation(simpleProduct)

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
            id: UUID(),
            name: "Parent Product",
            productImageSource: nil,
            productID: 123,
            allAttributes: []
        ))
        let expectedVariationItem = POSItem.variation(POSVariation(
            id: UUID(),
            name: "Variation",
            formattedPrice: "$15.00",
            price: "15.00",
            productImageSource: nil,
            productID: 123,
            variationID: 456,
            parentProductName: "Parent Product"
        ))

        mockProductsRemote.whenLoadingProductForPointOfSale(siteID: variation.siteID, productID: variation.parentID, thenReturn: .success(parentProduct))
        mockItemMapper.mockMappedProducts = [expectedParentItem]
        mockItemMapper.mockMappedVariations = [expectedVariationItem]

        // When
        let result = try await sut.itemForProductOrVariation(variation)

        // Then
        #expect(mockProductsRemote.invocationCountOfLoadPOSProduct == 1)
        #expect(mockProductsRemote.requestedProductIDsForFetchingPOSProduct.contains(variation.parentID))

        #expect(mockItemMapper.mapVariationsToPOSItemsCalled)
        #expect(mockItemMapper.mockVariations.count == 1)
        #expect(mockItemMapper.mockVariations.first?.productVariationID == 456)
        #expect(result == expectedVariationItem)
    }

    @Test("Throws error for downloadable product")
    func testThrowsErrorForDownloadableProduct() async {
        // Given
        let downloadableProduct = POSProduct.fake().copy(
            productID: 321,
            productTypeKey: "simple",
            downloadable: true
        )

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.downloadableProduct) {
            _ = try await sut.itemForProductOrVariation(downloadableProduct)
        }
    }


    @Test("Throws error for unknown product type (no mapped item)")
    func testThrowsErrorForUnknownProductTypeNoMappedItem() async {
        // Given
        let simpleProduct = POSProduct.fake().copy(
            productID: 999,
            productTypeKey: "simple"
        )
        mockItemMapper.mockMappedProducts = [] // Simulate no mapped item

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.unknown) {
            _ = try await sut.itemForProductOrVariation(simpleProduct)
        }
    }

    @Test("Throws error for unsupported product type")
    func testThrowsErrorForUnsupportedProductType() async {
        // Given
        let unsupportedProduct = POSProduct.fake().copy(
            productID: 789,
            productTypeKey: "grouped"
        )

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.unsupportedProductType) {
            _ = try await sut.itemForProductOrVariation(unsupportedProduct)
        }
    }

    @Test("Throws loadingError when parent product loading fails")
    func testThrowsLoadingErrorWhenParentProductFails() async {
        // Given
        let variation = POSProduct.fake().copy(
            productID: 456,
            productTypeKey: "variation",
            parentID: 123
        )
        let someError = NSError(domain: "Test", code: 1, userInfo: nil)
        mockProductsRemote.whenLoadingProductForPointOfSale(siteID: variation.siteID, productID: variation.parentID, thenReturn: .failure(someError))

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.loadingError(underlyingError: someError)) {
            _ = try await sut.itemForProductOrVariation(variation)
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

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.mappingError(underlyingError: ProductAttribute.ProductAttributeError.notFromAVariationAsAProduct)) {
            _ = try await sut.itemForProductOrVariation(variation)
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

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.noParentProductForVariation) {
            _ = try await sut.itemForProductOrVariation(variation)
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

        mockProductsRemote.whenLoadingProductForPointOfSale(siteID: variation.siteID, productID: variation.parentID, thenReturn: .success(parentProduct))
        mockItemMapper.mockMappedProducts = []

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.variationCouldNotBeConverted) {
            _ = try await sut.itemForProductOrVariation(variation)
        }
    }
}
