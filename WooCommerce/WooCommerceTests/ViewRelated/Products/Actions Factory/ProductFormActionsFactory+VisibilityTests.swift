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
                                                formType: .edit)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.priceSettings(editable: true)))
    }

    func testPriceRowIsVisibleForProductWithoutPriceData() {
        // Arrange
        let product = Fixtures.productWithoutPriceData
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.priceSettings(editable: true)))
    }

    // MARK: - Inventory

    func testInventoryRowIsVisibleForProductWithInventoryData() {
        // Arrange
        let product = Fixtures.productWithInventoryData
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.inventorySettings(editable: true)))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editInventorySettings))
    }

    func testInventoryRowIsInvisibleForProductWithMissingInventoryData() {
        // Arrange
        let product = Fixtures.productWithMissingInventoryData
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.inventorySettings(editable: true)))
        XCTAssertTrue(factory.bottomSheetActions().contains(.editInventorySettings))
    }

    // MARK: - Shipping

    func testShippingRowIsVisibleForProductWithShippingData() {
        // Arrange
        let product = Fixtures.productWithShippingData
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.shippingSettings(editable: true)))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editShippingSettings))
    }

    func testShippingRowIsInvisibleForProductWithMissingShippingData() {
        // Arrange
        let product = Fixtures.productWithMissingShippingData
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.shippingSettings(editable: true)))
        XCTAssertTrue(factory.bottomSheetActions().contains(.editShippingSettings))
    }

    // MARK: - Categories

    func testCategoriesRowIsVisibleForProductWithACategory() {
        // Arrange
        let product = Fixtures.productWithOneCategory
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.categories(editable: true)))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editCategories))
    }

    func testCategoriesRowIsInvisibleForProductWithoutCategories() {
        // Arrange
        let product = Fixtures.productWithoutCategories
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.categories(editable: true)))
        XCTAssertTrue(factory.bottomSheetActions().contains(.editCategories))
    }

    // MARK: - Short description

    func testShortDescriptionRowIsVisibleForProductWithNonEmptyShortDescription() {
        // Arrange
        let product = Fixtures.productWithNonEmptyShortDescription
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.shortDescription(editable: true)))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editShortDescription))
    }

    func testShortDescriptionRowIsInvisibleForProductWithoutShortDescription() {
        // Arrange
        let product = Fixtures.productWithEmptyShortDescription
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.shortDescription(editable: true)))
        XCTAssertTrue(factory.bottomSheetActions().contains(.editShortDescription))
    }

    // MARK: - Downloadable Files

    func test_downloadableFiles_row_is_visible_for_downloadable_product_with_non_empty_downloadableFiles() {
        // Arrange
        let product = Fixtures.downloadableProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.downloadableFiles))
    }

    func test_downloadableFiles_row_is_invisible_for_non_downloadable_product_without_downloadableFiles() {
        // Arrange
        let product = Fixtures.nonDownloadableProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.downloadableFiles))
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
        // Short description
        static let productWithNonEmptyShortDescription = MockProduct().product(shortDescription: "desc", productType: .simple)
        static let productWithEmptyShortDescription = MockProduct().product(shortDescription: "", productType: .simple)

        // Downloadable Files
        static let downloadableProduct = MockProduct().product(downloadable: true)
        static let nonDownloadableProduct = MockProduct().product(downloadable: false)

    }
}
