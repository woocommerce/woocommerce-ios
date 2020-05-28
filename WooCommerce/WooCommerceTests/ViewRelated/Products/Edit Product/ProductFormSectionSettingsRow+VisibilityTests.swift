import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductFormActionsFactory_VisibilityTests: XCTestCase {
    // MARK: - Price

    func testPriceRowIsVisibleForProductWithPriceData() {
        // Arrange
        let product = Fixtures.productWithPriceData

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.priceSettings))
        XCTAssertFalse(factory.bottomSheetActions().contains(.priceSettings))
    }

    func testPriceRowIsVisibleForProductWithoutPriceData() {
        // Arrange
        let product = Fixtures.productWithoutPriceData

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.priceSettings))
        XCTAssertFalse(factory.bottomSheetActions().contains(.priceSettings))
    }

    // MARK: - Inventory

    func testInventoryRowIsVisibleForProductWithInventoryData() {
        // Arrange
        let product = Fixtures.productWithInventoryData

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.inventorySettings))
        XCTAssertFalse(factory.bottomSheetActions().contains(.inventorySettings))
    }

    func testInventoryRowIsInvisibleForProductWithMissingInventoryData() {
        // Arrange
        let product = Fixtures.productWithMissingInventoryData

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.inventorySettings))
        XCTAssertTrue(factory.bottomSheetActions().contains(.inventorySettings))
    }

    // MARK: - Shipping

    func testShippingRowIsVisibleForProductWithShippingData() {
        // Arrange
        let product = Fixtures.productWithShippingData

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.shippingSettings))
        XCTAssertFalse(factory.bottomSheetActions().contains(.shippingSettings))
    }

    func testShippingRowIsInvisibleForProductWithMissingShippingData() {
        // Arrange
        let product = Fixtures.productWithMissingShippingData

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.shippingSettings))
        XCTAssertTrue(factory.bottomSheetActions().contains(.shippingSettings))
    }

    // MARK: - Categories

    func testCategoriesRowIsVisibleForProductWithACategory() {
        // Arrange
        let product = Fixtures.productWithOneCategory

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.categories))
        XCTAssertFalse(factory.bottomSheetActions().contains(.categories))
    }

    func testCategoriesRowIsInvisibleForProductWithoutCategories() {
        // Arrange
        let product = Fixtures.productWithoutCategories

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.categories))
        XCTAssertTrue(factory.bottomSheetActions().contains(.categories))
    }

    // MARK: - Brief description

    func testBriefDescriptionRowIsVisibleForProductWithNonEmptyBriefDescription() {
        // Arrange
        let product = Fixtures.productWithNonEmptyBriefDescription

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.briefDescription))
        XCTAssertFalse(factory.bottomSheetActions().contains(.briefDescription))
    }

    func testBriefDescriptionRowIsInvisibleForProductWithoutBriefDescription() {
        // Arrange
        let product = Fixtures.productWithEmptyBriefDescription

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.briefDescription))
        XCTAssertTrue(factory.bottomSheetActions().contains(.briefDescription))
    }
}

private extension ProductFormActionsFactory_VisibilityTests {
    enum Fixtures {
        // Price
        static let productWithPriceData = MockProduct().product(productType: .simple, regularPrice: "17")
        static let productWithoutPriceData = MockProduct().product(productType: .simple, regularPrice: nil, salePrice: nil)
        // Inventory
        static let productWithInventoryData = MockProduct().product(productType: .simple, manageStock: true, sku: "123")
        static let productWithMissingInventoryData = MockProduct().product(productType: .simple, manageStock: true, sku: nil, stockQuantity: nil)
        // Shipping
        static let productWithShippingData = MockProduct().product(productType: .simple,
                                                                   dimensions: ProductDimensions(length: "10", width: "0", height: "0"),
                                                                   weight: "100")
        static let productWithMissingShippingData = MockProduct().product(productType: .simple,
                                                                          dimensions: ProductDimensions(length: "", width: "", height: ""),
                                                                          weight: nil)
        // Categories
        static let productWithOneCategory = MockProduct().product(productType: .simple,
                                                                    categories: [ProductCategory(categoryID: 0, siteID: 0, parentID: 0, name: "", slug: "")])
        static let productWithoutCategories = MockProduct().product(productType: .simple, categories: [])
        // Brief description
        static let productWithNonEmptyBriefDescription = MockProduct().product(briefDescription: "desc", productType: .simple)
        static let productWithEmptyBriefDescription = MockProduct().product(briefDescription: "", productType: .simple)
    }
}
