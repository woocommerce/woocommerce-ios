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
        #expect(mockProductsRemote.invocationCountOfFetchPOSProduct == 1)
        #expect(mockProductsRemote.requestedProductIDsForFetchingPOSProduct.contains(variation.parentID))

        #expect(mockItemMapper.mapVariationsToPOSItemsCalled)
        #expect(mockItemMapper.mockVariations.count == 1)
        #expect(mockItemMapper.mockVariations.first?.productVariationID == 456)
        #expect(result == expectedVariationItem)
    }

    @Test("Throws error for unknown product type")
    func testThrowsErrorForUnknownProductType() async {
        // Given
        let unknownProduct = POSProduct.fake().copy(
            productID: 789,
            productTypeKey: "grouped"
        )

        // When/Then
        await #expect(throws: PointOfSaleBarcodeScanError.unknown) {
            _ = try await sut.itemForProductOrVariation(unknownProduct)
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
