import XCTest
import Fakes
import Yosemite
@testable import WooCommerce

final class ProductDetailsFactoryTests: XCTestCase {
    // MARK: Simple product type

    func test_factory_creates_product_form_for_simple_product() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue)

        let exp = expectation(description: #function)
        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             forceReadOnly: false) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                exp.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    // MARK: External/affiliate product type

    func test_factory_creates_product_form_for_affiliate_product() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.affiliate.rawValue)
        let exp = expectation(description: #function)

        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             forceReadOnly: false) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                exp.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    // MARK: Grouped product type

    func test_factory_creates_product_form_for_grouped_product() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.grouped.rawValue)
        let exp = expectation(description: #function)

        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             forceReadOnly: false) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                exp.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    // MARK: Variable product type

    func test_factory_creates_product_form_for_variable_product() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.variable.rawValue)
        let exp = expectation(description: #function)

        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             forceReadOnly: false) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                exp.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    // MARK: Non-core product type

    func test_factory_creates_product_form_for_non_core_product() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: "other")

        // Action
        waitForExpectation { expectation in
            ProductDetailsFactory.productDetails(product: product,
                                                 presentationStyle: .navigationStack,
                                                 forceReadOnly: false) { viewController in
                                                    // Assert
                                                    XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                    expectation.fulfill()
            }
        }
    }

    func test_factory_creates_readonly_product_details_for_product_when_forceReadOnly_is_on() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue)

        // Action
        waitForExpectation { expectation in
            ProductDetailsFactory.productDetails(product: product,
                                                 presentationStyle: .navigationStack,
                                                 forceReadOnly: true) { viewController in
                                                    // Assert
                                                    XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                    expectation.fulfill()
            }
        }
    }
}
