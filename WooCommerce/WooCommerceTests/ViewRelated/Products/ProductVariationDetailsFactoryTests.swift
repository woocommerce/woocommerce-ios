import XCTest
import Yosemite
import Fakes
@testable import WooCommerce

@MainActor
final class ProductVariationDetailsFactoryTests: XCTestCase {
    func test_factory_creates_product_variation_form() throws {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let parentProduct = Product.fake()

        // Action
        let viewController = waitFor { promise in
            ProductVariationDetailsFactory.productVariationDetails(productVariation: productVariation,
                                                                   parentProduct: parentProduct,
                                                                   presentationStyle: .navigationStack,
                                                                   forceReadOnly: false) { viewController in
                                                    promise(viewController)
            }
        }

        // Assert
        XCTAssertTrue(viewController is ProductFormViewController<ProductVariationFormViewModel>)
    }

    func test_factory_names_the_variation_only_from_attributes_used_for_variations() throws {
        // Given
        let productVariation = ProductVariation.fake().copy(attributes: [.init(id: 1, name: "Color", option: "Red")])
        let parentProduct = Product.fake().copy(attributes: [
            ProductAttribute.fake().copy(attributeID: 1, name: "Color", variation: true, options: ["Red", "Blue"]),
            ProductAttribute.fake().copy(attributeID: 0, name: "Material", variation: false, options: ["Cotton"])
        ])

        // When
        let viewController = waitFor { promise in
            ProductVariationDetailsFactory.productVariationDetails(productVariation: productVariation,
                                                                   parentProduct: parentProduct,
                                                                   presentationStyle: .navigationStack,
                                                                   forceReadOnly: false) { viewController in
                                                    promise(viewController)
            }
        }
        viewController.loadViewIfNeeded()

        // Then
        XCTAssertEqual(viewController.navigationItem.backButtonTitle, "Red")
    }
}
