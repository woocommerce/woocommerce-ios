import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductVariationGeneratorTests: XCTestCase {

    func test_all_variations_are_generated_correctly() {
        // Given
        let product = Product.fake().copy(attributes: [
            ProductAttribute.fake().copy(attributeID: 1, name: "Size", options: ["S", "M"]),
            ProductAttribute.fake().copy(attributeID: 2, name: "Color", options: ["Red", "Green"]),
            ProductAttribute.fake().copy(attributeID: 3, name: "Fabric", options: ["Cotton", "Nylon"]),
        ])

        // When
        let variations = ProductVariationGenerator.generateVariations(for: product, excluding: [])

        // Then
        XCTAssertEqual(variations, [
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "S"),
                                    .init(id: 2, name: "Color", option: "Red"),
                                    .init(id: 3, name: "Fabric", option: "Cotton")
                                   ],
                                   description: "",
                                   image: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "S"),
                                    .init(id: 2, name: "Color", option: "Red"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "S"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Cotton")
                                   ],
                                   description: "",
                                   image: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "S"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Red"),
                                    .init(id: 3, name: "Fabric", option: "Cotton")
                                   ],
                                   description: "",
                                   image: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Red"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Cotton")
                                   ],
                                   description: "",
                                   image: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil),
        ])
    }

    func test_existing_variations_are_excluded_correctly() {
        // Given
        let product = Product.fake().copy(attributes: [
            ProductAttribute.fake().copy(attributeID: 1, name: "Size", options: ["S", "M"]),
            ProductAttribute.fake().copy(attributeID: 2, name: "Color", options: ["Red", "Green"]),
            ProductAttribute.fake().copy(attributeID: 3, name: "Fabric", options: ["Cotton", "Nylon"]),
        ])

        let existingVariations = [
            ProductVariation.fake().copy(attributes: [
                .init(id: 1, name: "Size", option: "M"),
                .init(id: 2, name: "Color", option: "Green"),
                .init(id: 3, name: "Fabric", option: "Cotton"),
            ]),
            ProductVariation.fake().copy(attributes: [
                .init(id: 1, name: "Size", option: "S"),
                .init(id: 2, name: "Color", option: "Red"),
                .init(id: 3, name: "Fabric", option: "Nylon"),
            ])
        ]

        // When
        let variations = ProductVariationGenerator.generateVariations(for: product, excluding: existingVariations)

        // Then
        XCTAssertEqual(variations, [
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "S"),
                                    .init(id: 2, name: "Color", option: "Red"),
                                    .init(id: 3, name: "Fabric", option: "Cotton")
                                   ],
                                   description: "",
                                   image: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "S"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Cotton")
                                   ],
                                   description: "",
                                   image: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "S"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Red"),
                                    .init(id: 3, name: "Fabric", option: "Cotton")
                                   ],
                                   description: "",
                                   image: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Red"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil),
        ])
    }
}
