import Testing
import WooFoundation
@testable import Yosemite

struct PointOfSaleItemMapperTests {
    private var currencySettings: CurrencySettings!
    private var sut: PointOfSaleItemMapper!

    init() {
        currencySettings = CurrencySettings()
        sut = PointOfSaleItemMapper(currencySettings: currencySettings)
    }

    @Test func mapProductsToPOSItems_returns_simple_product_when_given_simple_product() {
        // Given
        let product = POSProduct.fake().copy(productID: 123,
                                             name: "Test Product",
                                             productTypeKey: "simple",
                                             price: "10.00",
                                             images: [.fake().copy(src: "https://example.com/image.jpg")],
                                             manageStock: true,
                                             stockQuantity: 10,
                                             stockStatusKey: "instock"
        )

        // When
        let items = sut.mapProductsToPOSItems(products: [product])

        // Then
        #expect(items.count == 1)
        guard case let .simpleProduct(simpleProduct) = items.first else {
            Issue.record("Expected simple product, but got \(String(describing: items.first))")
            return
        }
        #expect(simpleProduct.name == "Test Product")
        #expect(simpleProduct.price == "10.00")
        #expect(simpleProduct.productID == 123)
        #expect(simpleProduct.manageStock == true)
        #expect(simpleProduct.stockQuantity == 10)
        #expect(simpleProduct.stockStatusKey == "instock")
        #expect(simpleProduct.productImageSource == "https://example.com/image.jpg")
    }

    @Test func mapProductsToPOSItems_returns_variable_product_when_given_variable_product() throws {
        // Given
        let attributes = [ProductAttribute.fake().copy(name: "Color", variation: true, options: ["Red", "Blue"])]
        let product = POSProduct.fake().copy(
            productID: 123,
            name: "Test Variable Product",
            productTypeKey: "variable",
            images: [.fake().copy(src: "https://example.com/image.jpg")],
            attributes: attributes
        )

        // When
        let items = sut.mapProductsToPOSItems(products: [product])

        // Then
        #expect(items.count == 1)
        guard case let .variableParentProduct(variableProduct) = items.first else {
            Issue.record("Expected variable product, but got \(String(describing: items.first))")
            return
        }
        #expect(variableProduct.name == "Test Variable Product")
        #expect(variableProduct.productID == 123)
        #expect(variableProduct.productImageSource == "https://example.com/image.jpg")
        #expect(variableProduct.allAttributes.count == 1)
        let attribute = try #require(variableProduct.allAttributes.first)
        #expect(attribute.name == "Color")
        #expect(attribute.options == ["Red", "Blue"])
    }

    @Test func mapProductsToPOSItems_returns_nil_for_unsupported_product_type() {
        // Given
        let product = POSProduct.fake().copy(productTypeKey: "grouped")

        // When
        let items = sut.mapProductsToPOSItems(products: [product])

        // Then
        #expect(items.isEmpty)
    }

    @Test func mapVariationsToPOSItems_returns_variation_items() {
        // Given
        let parentProduct = POSVariableParentProduct(
            id: UUID(),
            name: "Parent Product",
            productImageSource: nil,
            productID: 123,
            allAttributes: [ProductAttribute.fake().copy(name: "Color", options: ["Red", "Blue"])]
        )
        let variation = ProductVariation.fake().copy(
            productID: 123,
            productVariationID: 456,
            attributes: [ProductVariationAttribute.fake().copy(name: "Color", option: "Red")],
            image: .fake().copy(src: "https://example.com/variation.jpg"),
            price: "15.00"
        )

        // When
        let items = sut.mapVariationsToPOSItems(variations: [variation], parentProduct: parentProduct)

        // Then
        #expect(items.count == 1)
        guard case let .variation(variationItem) = items.first else {
            Issue.record("Expected variation, but got \(String(describing: items.first))")
            return
        }
        #expect(variationItem.name == "Color: Red")
        #expect(variationItem.price == "15.00")
        #expect(variationItem.productID == 123)
        #expect(variationItem.productVariationID == 456)
        #expect(variationItem.productImageSource == "https://example.com/variation.jpg")
        #expect(variationItem.parentProductName == "Parent Product")
    }

    @Test func formatPrice_returns_formatted_price() {
        // Given
        let product = POSProduct.fake().copy(productTypeKey: "simple", price: "10.00")

        // When
        let items = sut.mapProductsToPOSItems(products: [product])

        // Then
        guard case let .simpleProduct(simpleProduct) = items.first else {
            Issue.record("Expected simple product, but got \(String(describing: items.first))")
            return
        }
        #expect(simpleProduct.formattedPrice == "$10.00")
    }

    @Test func formatPrice_returns_$0_for_invalid_price() {
        // Given
        let product = POSProduct.fake().copy(productTypeKey: "simple", price: "invalid")

        // When
        let items = sut.mapProductsToPOSItems(products: [product])

        // Then
        guard case let .simpleProduct(simpleProduct) = items.first else {
            Issue.record("Expected simple product, but got \(String(describing: items.first))")
            return
        }
        #expect(simpleProduct.formattedPrice == "$0.00")
    }
}
