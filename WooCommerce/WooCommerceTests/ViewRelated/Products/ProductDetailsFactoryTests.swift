import XCTest
@testable import WooCommerce

final class ProductDetailsFactoryTests: XCTestCase {
    func testFactoryCreatesProductFormForSimpleProductWhenProductsFeatureSwitchIsOn() {
        // Arrange
        let mockStoresManager = MockProductsAppSettingsStoresManager(isProductsFeatureSwitchEnabled: true, sessionManager: SessionManager.testingInstance)
        ServiceLocator.setStores(mockStoresManager)

        let product = MockProduct().product(productType: .simple)

        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")
        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testFactoryCreatesProductFormForSimpleProductWhenProductsFeatureSwitchIsOff() {
        // Arrange
        let mockStoresManager = MockProductsAppSettingsStoresManager(isProductsFeatureSwitchEnabled: false, sessionManager: SessionManager.testingInstance)
        ServiceLocator.setStores(mockStoresManager)

        let product = MockProduct().product(productType: .simple)

        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")
        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testFactoryCreatesReadonlyProductDetailsForNonSimpleProductWhenProductsFeatureSwitchIsOn() {
        // Arrange
        let mockStoresManager = MockProductsAppSettingsStoresManager(isProductsFeatureSwitchEnabled: true, sessionManager: SessionManager.testingInstance)
        ServiceLocator.setStores(mockStoresManager)

        let product = MockProduct().product(productType: .affiliate)

        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")
        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductDetailsViewController)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }
}
