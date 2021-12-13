import XCTest
import Yosemite
import Fakes
@testable import WooCommerce

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
}
