import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductFormActionsFactory_VisibilityTests: XCTestCase {
    // MARK: - Price

    func testPriceRowIsVisibleForProductWithPriceData() {
        // Arrange
        let product = Fixtures.productWithPriceData
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.priceSettings))
    }

    func testPriceRowIsVisibleForProductWithoutPriceData() {
        // Arrange
        let product = Fixtures.productWithoutPriceData
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.priceSettings))
    }

    // MARK: - Inventory

    func testInventoryRowIsVisibleForProductWithInventoryData() {
        // Arrange
        let product = Fixtures.productWithInventoryData
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.inventorySettings))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editInventorySettings))
    }

    func testInventoryRowIsInvisibleForProductWithMissingInventoryData() {
        // Arrange
        let product = Fixtures.productWithMissingInventoryData
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.inventorySettings))
        XCTAssertTrue(factory.bottomSheetActions().contains(.editInventorySettings))
    }

    // MARK: - Shipping

    func testShippingRowIsVisibleForProductWithShippingData() {
        // Arrange
        let product = Fixtures.productWithShippingData
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.shippingSettings))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editShippingSettings))
    }

    func testShippingRowIsInvisibleForProductWithMissingShippingData() {
        // Arrange
        let product = Fixtures.productWithMissingShippingData
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.shippingSettings))
        XCTAssertTrue(factory.bottomSheetActions().contains(.editShippingSettings))
    }

    // MARK: - Categories

    func testCategoriesRowIsVisibleForProductWithACategory() {
        // Arrange
        let product = Fixtures.productWithOneCategory
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.categories))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editCategories))
    }

    func testCategoriesRowIsInvisibleForProductWithoutCategories() {
        // Arrange
        let product = Fixtures.productWithoutCategories
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.categories))
        XCTAssertTrue(factory.bottomSheetActions().contains(.editCategories))
    }

    // MARK: - Brief description

    func testBriefDescriptionRowIsVisibleForProductWithNonEmptyBriefDescription() {
        // Arrange
        let product = Fixtures.productWithNonEmptyBriefDescription
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.briefDescription))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editBriefDescription))
    }

    func testBriefDescriptionRowIsInvisibleForProductWithoutBriefDescription() {
        // Arrange
        let product = Fixtures.productWithEmptyBriefDescription
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.briefDescription))
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
