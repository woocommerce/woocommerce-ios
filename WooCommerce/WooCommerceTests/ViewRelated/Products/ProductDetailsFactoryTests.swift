import XCTest
import Fakes
import Yosemite
@testable import WooCommerce

final class ProductDetailsFactoryTests: XCTestCase {
    // MARK: Simple product type

    func test_factory_creates_product_form_for_simple_product_when_products_release_3_is_on() {
        // Arrange
        let mockStoresManager = MockProductsAppSettingsStoresManager(isProductsFeatureSwitchEnabled: true, sessionManager: SessionManager.testingInstance)

        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue)

        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")
        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             stores: mockStoresManager,
                                             forceReadOnly: false) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func test_factory_creates_product_form_for_simple_product_when_products_release_3_is_off() {
        // Arrange
        let mockStoresManager = MockProductsAppSettingsStoresManager(isProductsFeatureSwitchEnabled: false, sessionManager: SessionManager.testingInstance)

        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue)

        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")
        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             stores: mockStoresManager,
                                             forceReadOnly: false) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    // MARK: External/affiliate product type

    func test_factory_creates_product_form_for_affiliate_product_when_products_release_3_is_on() {
        // Arrange
        let mockStoresManager = MockProductsAppSettingsStoresManager(isProductsFeatureSwitchEnabled: true, sessionManager: SessionManager.testingInstance)

        let product = Product.fake().copy(productTypeKey: ProductType.affiliate.rawValue)
        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")

        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             stores: mockStoresManager,
                                             forceReadOnly: false) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func test_factory_creates_product_form_for_affiliate_product_when_products_release_3_is_off() {
        // Arrange
        let mockStoresManager = MockProductsAppSettingsStoresManager(isProductsFeatureSwitchEnabled: false, sessionManager: SessionManager.testingInstance)
        let product = Product.fake().copy(productTypeKey: ProductType.affiliate.rawValue)
        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")

        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             stores: mockStoresManager,
                                             forceReadOnly: false) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    // MARK: Grouped product type

    func test_factory_creates_product_form_for_grouped_product_when_products_release_3_is_on() {
        // Arrange
        let mockStoresManager = MockProductsAppSettingsStoresManager(isProductsFeatureSwitchEnabled: true, sessionManager: SessionManager.testingInstance)
        let product = Product.fake().copy(productTypeKey: ProductType.grouped.rawValue)
        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")

        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             stores: mockStoresManager,
                                             forceReadOnly: false) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func test_factory_creates_product_form_for_grouped_product_when_products_release_3_is_off() {
        // Arrange
        let mockStoresManager = MockProductsAppSettingsStoresManager(isProductsFeatureSwitchEnabled: false, sessionManager: SessionManager.testingInstance)
        let product = Product.fake().copy(productTypeKey: ProductType.grouped.rawValue)
        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")

        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             stores: mockStoresManager,
                                             forceReadOnly: false) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    // MARK: Variable product type

    func test_factory_creates_product_form_for_variable_product_when_products_release_3_is_on() {
        // Arrange
        let mockStoresManager = MockProductsAppSettingsStoresManager(isProductsFeatureSwitchEnabled: true, sessionManager: SessionManager.testingInstance)
        let product = Product.fake().copy(productTypeKey: ProductType.variable.rawValue)
        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")

        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             stores: mockStoresManager,
                                             forceReadOnly: false) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func test_factory_creates_product_form_for_variable_product_when_products_release_3_is_off() {
        // Arrange
        let mockStoresManager = MockProductsAppSettingsStoresManager(isProductsFeatureSwitchEnabled: false, sessionManager: SessionManager.testingInstance)
        let product = Product.fake().copy(productTypeKey: ProductType.variable.rawValue)
        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")

        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             stores: mockStoresManager,
                                             forceReadOnly: false) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    // MARK: Non-core product type

    func test_factory_creates_product_form_for_non_core_product_when_products_release_3_is_on() {
        // Arrange
        let mockStoresManager = MockProductsAppSettingsStoresManager(isProductsFeatureSwitchEnabled: true, sessionManager: SessionManager.testingInstance)
        let product = Product.fake().copy(productTypeKey: "other")

        // Action
        waitForExpectation { expectation in
            ProductDetailsFactory.productDetails(product: product,
                                                 presentationStyle: .navigationStack,
                                                 stores: mockStoresManager,
                                                 forceReadOnly: false) { viewController in
                                                    // Assert
                                                    XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                    expectation.fulfill()
            }
        }
    }

    func test_factory_creates_product_form_for_non_core_product_when_products_release_3_is_off() {
        // Arrange
        let mockStoresManager = MockProductsAppSettingsStoresManager(isProductsFeatureSwitchEnabled: false, sessionManager: SessionManager.testingInstance)
        let product = Product.fake().copy(productTypeKey: "other")

        // Action
        waitForExpectation { expectation in
            ProductDetailsFactory.productDetails(product: product,
                                                 presentationStyle: .navigationStack,
                                                 stores: mockStoresManager,
                                                 forceReadOnly: false) { viewController in
                                                    // Assert
                                                    XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                    expectation.fulfill()
            }
        }
    }

    func test_factory_creates_readonly_product_details_for_product_when_forceReadOnly_is_on() {
        // Arrange
        let mockStoresManager = MockProductsAppSettingsStoresManager(isProductsFeatureSwitchEnabled: false, sessionManager: SessionManager.testingInstance)
        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue)

        // Action
        waitForExpectation { expectation in
            ProductDetailsFactory.productDetails(product: product,
                                                 presentationStyle: .navigationStack,
                                                 stores: mockStoresManager,
                                                 forceReadOnly: true) { viewController in
                                                    // Assert
                                                    XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
                                                    expectation.fulfill()
            }
        }
    }
}
