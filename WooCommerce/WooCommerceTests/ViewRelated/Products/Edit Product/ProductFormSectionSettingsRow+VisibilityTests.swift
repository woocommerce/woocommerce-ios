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
        XCTAssertTrue(factory.settingsSectionActions().contains(.editPriceSettings))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editPriceSettings))
    }

    func testPriceRowIsVisibleForProductWithoutPriceData() {
        // Arrange
        let product = Fixtures.productWithoutPriceData

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.editPriceSettings))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editPriceSettings))
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
        XCTAssertTrue(factory.settingsSectionActions().contains(.editInventorySettings))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editInventorySettings))
    }

    func testInventoryRowIsInvisibleForProductWithMissingInventoryData() {
        // Arrange
        let product = Fixtures.productWithMissingInventoryData

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.editInventorySettings))
        XCTAssertTrue(factory.bottomSheetActions().contains(.editInventorySettings))
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
        XCTAssertTrue(factory.settingsSectionActions().contains(.editShippingSettings))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editShippingSettings))
    }

    func testShippingRowIsInvisibleForProductWithMissingShippingData() {
        // Arrange
        let product = Fixtures.productWithMissingShippingData

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.editShippingSettings))
        XCTAssertTrue(factory.bottomSheetActions().contains(.editShippingSettings))
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
        XCTAssertTrue(factory.settingsSectionActions().contains(.editCategories))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editCategories))
    }

    func testCategoriesRowIsInvisibleForProductWithoutCategories() {
        // Arrange
        let product = Fixtures.productWithoutCategories

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.editCategories))
        XCTAssertTrue(factory.bottomSheetActions().contains(.editCategories))
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
        XCTAssertTrue(factory.settingsSectionActions().contains(.editBriefDescription))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editBriefDescription))
    }

    func testBriefDescriptionRowIsInvisibleForProductWithoutBriefDescription() {
        // Arrange
        let product = Fixtures.productWithEmptyBriefDescription

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.editBriefDescription))
        XCTAssertTrue(factory.bottomSheetActions().contains(.editBriefDescription))
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
