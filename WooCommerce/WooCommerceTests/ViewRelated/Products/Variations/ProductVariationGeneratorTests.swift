import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductVariationGeneratorTests: XCTestCase {

    func test_all_variations_are_generated_correctly_for_regular_variable_product() {
        // Given
        let product = Product.fake().copy(attributes: [
            ProductAttribute.fake().copy(attributeID: 1, name: "Size", variation: true, options: ["S", "M"]),
            ProductAttribute.fake().copy(attributeID: 2, name: "Color", variation: true, options: ["Red", "Green"]),
            ProductAttribute.fake().copy(attributeID: 3, name: "Fabric", variation: true, options: ["Cotton", "Nylon"]),
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
                                   image: nil,
                                   subscription: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "S"),
                                    .init(id: 2, name: "Color", option: "Red"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "S"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Cotton")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "S"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Red"),
                                    .init(id: 3, name: "Fabric", option: "Cotton")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Red"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Cotton")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: nil),
        ])
    }

    func test_all_variations_are_generated_correctly_for_subscription_variable_product() {
        // Given
        let product = Product.fake().copy(productTypeKey: ProductType.variableSubscription.rawValue,
                                          attributes: [
            ProductAttribute.fake().copy(attributeID: 1, name: "Size", variation: true, options: ["S", "M"]),
            ProductAttribute.fake().copy(attributeID: 2, name: "Color", variation: true, options: ["Red", "Green"]),
            ProductAttribute.fake().copy(attributeID: 3, name: "Fabric", variation: true, options: ["Cotton", "Nylon"]),
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
                                   image: nil,
                                   subscription: .empty),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "S"),
                                    .init(id: 2, name: "Color", option: "Red"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: .empty),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "S"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Cotton")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: .empty),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "S"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: .empty),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Red"),
                                    .init(id: 3, name: "Fabric", option: "Cotton")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: .empty),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Red"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: .empty),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Cotton")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: .empty),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: .empty),
        ])
    }

    func test_attributes_not_used_for_variations_are_not_used_to_generate_variations() {
        // Given
        let product = Product.fake().copy(attributes: [
            ProductAttribute.fake().copy(attributeID: 1, name: "Size", variation: true, options: ["S", "M"]),
            ProductAttribute.fake().copy(attributeID: 0, name: "Material", variation: false, options: ["Cotton", "Wool"]),
        ])

        // When
        let variations = ProductVariationGenerator.generateVariations(for: product, excluding: [])

        // Then
        XCTAssertEqual(variations.map { $0.attributes }, [
            [.init(id: 1, name: "Size", option: "S")],
            [.init(id: 1, name: "Size", option: "M")]
        ])
    }

    func test_existing_variations_are_excluded_correctly() {
        // Given
        let product = Product.fake().copy(attributes: [
            ProductAttribute.fake().copy(attributeID: 1, name: "Size", variation: true, options: ["S", "M"]),
            ProductAttribute.fake().copy(attributeID: 2, name: "Color", variation: true, options: ["Red", "Green"]),
            ProductAttribute.fake().copy(attributeID: 3, name: "Fabric", variation: true, options: ["Cotton", "Nylon"]),
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
                                   image: nil,
                                   subscription: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "S"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Cotton")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "S"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Red"),
                                    .init(id: 3, name: "Fabric", option: "Cotton")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Red"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: nil),
            CreateProductVariation(regularPrice: "",
                                   salePrice: "",
                                   attributes: [
                                    .init(id: 1, name: "Size", option: "M"),
                                    .init(id: 2, name: "Color", option: "Green"),
                                    .init(id: 3, name: "Fabric", option: "Nylon")
                                   ],
                                   description: "",
                                   image: nil,
                                   subscription: nil),
        ])
    }
}
