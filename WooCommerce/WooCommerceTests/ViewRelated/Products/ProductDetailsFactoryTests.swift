import XCTest
@testable import WooCommerce

final class ProductDetailsFactoryTests: XCTestCase {
    // MARK: Simple product type

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

    // MARK: External/affiliate product type

    func testFactoryCreatesProductFormForAffiliateProductWhenProductsRelease3IsOn() {
        // Arrange
        let featureFlagService = MockFeatureFlagService(isEditProductsRelease2On: true, isEditProductsRelease3On: true)
        let product = MockProduct().product(productType: .affiliate)
        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")

        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             featureFlagService: featureFlagService) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testFactoryCreatesReadonlyProductDetailsForAffiliateProductWhenProductsRelease3IsOff() {
        // Arrange
        let featureFlagService = MockFeatureFlagService(isEditProductsRelease2On: true, isEditProductsRelease3On: false)
        let product = MockProduct().product(productType: .affiliate)
        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")

        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             featureFlagService: featureFlagService) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductDetailsViewController)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    // MARK: Grouped product type

    func testFactoryCreatesProductFormForGroupedProductWhenProductsRelease3IsOn() {
        // Arrange
        let featureFlagService = MockFeatureFlagService(isEditProductsRelease2On: true, isEditProductsRelease3On: true)
        let product = MockProduct().product(productType: .grouped)
        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")

        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             featureFlagService: featureFlagService) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testFactoryCreatesReadonlyProductDetailsForGroupedProductWhenProductsRelease3IsOff() {
        // Arrange
        let featureFlagService = MockFeatureFlagService(isEditProductsRelease2On: true, isEditProductsRelease3On: false)
        let product = MockProduct().product(productType: .grouped)
        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")

        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             featureFlagService: featureFlagService) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductDetailsViewController)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    // MARK: Non-editable product types

    func testFactoryCreatesProductFormForVariableProductWhenProductsRelease3IsOn() {
        // Arrange
        let featureFlagService = MockFeatureFlagService(isEditProductsRelease2On: true, isEditProductsRelease3On: true)
        let product = MockProduct().product(productType: .variable)
        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")

        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             featureFlagService: featureFlagService) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductFormViewController)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testFactoryCreatesReadonlyProductDetailsForVariableProductWhenProductsRelease3IsOff() {
        // Arrange
        let featureFlagService = MockFeatureFlagService(isEditProductsRelease2On: true, isEditProductsRelease3On: false)
        let product = MockProduct().product(productType: .variable)
        let expectation = self.expectation(description: "Wait for loading Products feature switch from app settings")

        // Action
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             featureFlagService: featureFlagService) { viewController in
                                                // Assert
                                                XCTAssertTrue(viewController is ProductDetailsViewController)
                                                expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }
}
