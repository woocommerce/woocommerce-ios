import Foundation
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

    @Test("Map products to POS items with different combinations",
          arguments: [
            // Test single simple product
            [createSimpleProduct1()],
            // Test single variable product
            [createVariableProduct1()],
            // Test mixed product types
            [createSimpleProduct1(), createVariableProduct1()],
            // Test multiple simple products
            [createSimpleProduct1(), createSimpleProduct2()],
            // Test multiple variable products
            [createVariableProduct1(), createVariableProduct2()],
            // Test unsupported product type
            [POSProduct.fake().copy(productTypeKey: "grouped")]
          ])
    func mapProductsToPOSItemsWithCombinations(products: [POSProduct]) {
        // When
        let items = sut.mapProductsToPOSItems(products: products)

        // Then
        if products.contains(where: { $0.productTypeKey == "grouped" }) {
            #expect(items.isEmpty)
            return
        }

        #expect(items.count == products.count)

        // Verify each product is mapped correctly
        for (index, product) in products.enumerated() {
            switch product.productTypeKey {
            case "simple":
                guard case let .simpleProduct(mappedProduct) = items[index] else {
                    Issue.record("Expected simple product at index \(index), but got \(String(describing: items[index]))")
                    return
                }
                #expect(mappedProduct.name == product.name)
                #expect(mappedProduct.price == product.price)
                #expect(mappedProduct.productID == product.productID)
                #expect(mappedProduct.productImageSource == product.images.first?.src)
                #expect(mappedProduct.manageStock == product.manageStock)
                #expect(mappedProduct.stockQuantity == product.stockQuantity)
                #expect(mappedProduct.stockStatusKey == product.stockStatusKey)

            case "variable":
                guard case let .variableParentProduct(mappedProduct) = items[index] else {
                    Issue.record("Expected variable product at index \(index), but got \(String(describing: items[index]))")
                    return
                }
                #expect(mappedProduct.name == product.name)
                #expect(mappedProduct.productID == product.productID)
                #expect(mappedProduct.productImageSource == product.images.first?.src)

                let sourceAttributes = product.attributes.filter { $0.variation }
                #expect(mappedProduct.allAttributes.count == sourceAttributes.count)
                for attribute in mappedProduct.allAttributes {
                    #expect(sourceAttributes.contains { $0.name == attribute.name })
                    #expect(sourceAttributes.contains { $0.options == attribute.options })
                }

            default:
                Issue.record("Unexpected product type: \(product.productTypeKey)")
                return
            }
        }
    }

    @Test("Map variations to POS items with different counts",
          arguments: [
            // Test single variation
            ([createVariation1()], createParentProduct()),
            // Test multiple variations
            ([createVariation1(), createVariation2()], createParentProduct()),
            // Test empty variations array
            ([], createParentProduct())
          ])
    func mapVariationsToPOSItemsWithCount(
        variations: [POSProductVariation],
        parentProduct: POSVariableParentProduct
    ) {
        // When
        let items = sut.mapVariationsToPOSItems(variations: variations, parentProduct: parentProduct)

        // Then
        #expect(items.count == variations.count)

        // Verify each variation is mapped correctly
        for (index, variation) in variations.enumerated() {
            guard case let .variation(mappedVariation) = items[index] else {
                Issue.record("Expected variation at index \(index), but got \(String(describing: items[index]))")
                return
            }
            #expect(mappedVariation.name == "Color: \(variation.attributes.first?.option ?? "")")
            #expect(mappedVariation.price == variation.price)
            #expect(mappedVariation.productVariationID == variation.productVariationID)
            #expect(mappedVariation.productImageSource == variation.image?.src)
            #expect(mappedVariation.parentProductName == parentProduct.name)
            #expect(mappedVariation.productID == parentProduct.productID)
            #expect(mappedVariation.productID == variation.productID)
        }
    }

    @Test("Format price correctly",
          arguments: [
            // Test valid price
            (POSProduct.fake().copy(productTypeKey: "simple", price: "10.00"), "$10.00"),
            // Test invalid price
            (POSProduct.fake().copy(productTypeKey: "simple", price: "invalid"), "$0.00"),
            // Test zero price
            (POSProduct.fake().copy(productTypeKey: "simple", price: "0.00"), "$0.00"),
            // Test negative price
            (POSProduct.fake().copy(productTypeKey: "simple", price: "-5.00"), "-$5.00")
          ])
    func formatPrice(product: POSProduct, expectedPrice: String) {
        // When
        let items = sut.mapProductsToPOSItems(products: [product])

        // Then
        guard case let .simpleProduct(simpleProduct) = items.first else {
            Issue.record("Expected simple product, but got \(String(describing: items.first))")
            return
        }
        #expect(simpleProduct.formattedPrice == expectedPrice)
    }

    // MARK: - Test Data Factory Methods

    private static func createSimpleProduct1() -> POSProduct {
        POSProduct.fake().copy(
            productID: 123,
            name: "Simple Product 1",
            productTypeKey: "simple",
            price: "10.00",
            images: [.fake().copy(src: "https://example.com/image1.jpg")],
            manageStock: true,
            stockQuantity: 10,
            stockStatusKey: "instock"
        )
    }

    private static func createSimpleProduct2() -> POSProduct {
        POSProduct.fake().copy(
            productID: 124,
            name: "Simple Product 2",
            productTypeKey: "simple",
            price: "20.00",
            images: [.fake().copy(src: "https://example.com/image2.jpg")],
            manageStock: true,
            stockQuantity: 5,
            stockStatusKey: "instock"
        )
    }

    private static func createVariableProduct1() -> POSProduct {
        POSProduct.fake().copy(
            productID: 125,
            name: "Variable Product 1",
            productTypeKey: "variable",
            images: [.fake().copy(src: "https://example.com/image3.jpg")],
            attributes: [ProductAttribute.fake().copy(name: "Color", variation: true, options: ["Red", "Blue"])]
        )
    }

    private static func createVariableProduct2() -> POSProduct {
        POSProduct.fake().copy(
            productID: 126,
            name: "Variable Product 2",
            productTypeKey: "variable",
            images: [.fake().copy(src: "https://example.com/image4.jpg")],
            attributes: [ProductAttribute.fake().copy(name: "Size", variation: true, options: ["S", "M", "L"])]
        )
    }

    private static func createParentProduct() -> POSVariableParentProduct {
        POSVariableParentProduct(
            id: UUID(),
            name: "Parent Product",
            productImageSource: nil,
            productID: 125,
            allAttributes: [ProductAttribute.fake().copy(name: "Color", options: ["Red", "Blue"])]
        )
    }

    private static func createVariation1() -> POSProductVariation {
        POSProductVariation.fake().copy(
            productID: 125,
            productVariationID: 456,
            attributes: [ProductVariationAttribute.fake().copy(name: "Color", option: "Red")],
            image: .fake().copy(src: "https://example.com/variation1.jpg"),
            price: "15.00"
        )
    }

    private static func createVariation2() -> POSProductVariation {
        POSProductVariation.fake().copy(
            productID: 125,
            productVariationID: 457,
            attributes: [ProductVariationAttribute.fake().copy(name: "Color", option: "Blue")],
            image: .fake().copy(src: "https://example.com/variation2.jpg"),
            price: "20.00"
        )
    }
}
