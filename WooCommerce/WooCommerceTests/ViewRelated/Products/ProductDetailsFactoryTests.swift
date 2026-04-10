import XCTest
import Fakes
import Yosemite
@testable import WooCommerce

final class ProductDetailsFactoryTests: XCTestCase {
    // MARK: Simple product type

    func test_factory_creates_product_form_for_simple_product() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue)

        // Action
        let viewController = ProductDetailsFactory.productDetails(product: product,
                                                                  presentationStyle: .navigationStack,
                                                                  forceReadOnly: false)

        // Assert
        XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
    }

    // MARK: External/affiliate product type

    func test_factory_creates_product_form_for_affiliate_product() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.affiliate.rawValue)

        // Action
        let viewController = ProductDetailsFactory.productDetails(product: product,
                                                                  presentationStyle: .navigationStack,
                                                                  forceReadOnly: false)

        // Assert
        XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
    }

    // MARK: Grouped product type

    func test_factory_creates_product_form_for_grouped_product() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.grouped.rawValue)

        // Action
        let viewController = ProductDetailsFactory.productDetails(product: product,
                                                                  presentationStyle: .navigationStack,
                                                                  forceReadOnly: false)
        // Assert
        XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
    }

    // MARK: Variable product type

    func test_factory_creates_product_form_for_variable_product() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.variable.rawValue)

        // Action
        let viewController = ProductDetailsFactory.productDetails(product: product,
                                                                  presentationStyle: .navigationStack,
                                                                  forceReadOnly: false)

        // Assert
        XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
    }

    // MARK: Non-core product type

    func test_factory_creates_product_form_for_non_core_product() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: "other")

        // Action
        let viewController = ProductDetailsFactory.productDetails(product: product,
                                                                  presentationStyle: .navigationStack,
                                                                  forceReadOnly: false)
        // Assert
        XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
    }

    func test_factory_creates_readonly_product_details_for_product_when_forceReadOnly_is_on() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue)

        // Action
        let viewController = ProductDetailsFactory.productDetails(product: product,
                                                                  presentationStyle: .navigationStack,
                                                                  forceReadOnly: true)
        // Assert
        XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
    }
}
