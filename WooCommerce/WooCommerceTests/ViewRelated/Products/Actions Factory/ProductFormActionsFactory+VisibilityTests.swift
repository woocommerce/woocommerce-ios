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
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.priceSettings(editable: true, hideSeparator: false)))
    }

    func testPriceRowIsVisibleForProductWithoutPriceData() {
        // Arrange
        let product = Fixtures.productWithoutPriceData
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.priceSettings(editable: true, hideSeparator: false)))
    }

    // MARK: - Inventory

    func testInventoryRowIsVisibleForProductWithInventoryData() {
        // Arrange
        let product = Fixtures.productWithInventoryData
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.inventorySettings(editable: true)))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editInventorySettings))
    }

    func testInventoryRowIsInvisibleForProductWithMissingInventoryData() {
        // Arrange
        let product = Fixtures.productWithMissingInventoryData
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

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
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.shippingSettings(editable: true)))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editShippingSettings))
    }

    func testShippingRowIsInvisibleForProductWithMissingShippingData() {
        // Arrange
        let product = Fixtures.productWithMissingShippingData
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

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
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.categories(editable: true)))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editCategories))
    }

    func testCategoriesRowIsInvisibleForProductWithoutCategories() {
        // Arrange
        let product = Fixtures.productWithoutCategories
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

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
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.shortDescription(editable: true)))
        XCTAssertFalse(factory.bottomSheetActions().contains(.editShortDescription))
    }

    func testShortDescriptionRowIsInvisibleForProductWithoutShortDescription() {
        // Arrange
        let product = Fixtures.productWithEmptyShortDescription
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.shortDescription(editable: true)))
        XCTAssertTrue(factory.bottomSheetActions().contains(.editShortDescription))
    }

    // MARK: - Downloadable Files

    func test_downloadableFiles_row_is_visible_for_downloadable_product_with_non_empty_downloadableFiles() {
        // Arrange
        let product = Fixtures.downloadableProduct.copy(downloads: [.fake()])
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.downloadableFiles(editable: true)))
    }

    func test_downloadableFiles_row_is_invisible_for_non_downloadable_product_without_downloadableFiles() {
        // Arrange
        let product = Fixtures.nonDownloadableProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.downloadableFiles(editable: true)))
    }

    // MARK: - Custom fields

    func test_givenExistingProductAndCustomFields_whenCreatingActions_thenCustomFieldsRowIsVisible() {
        // Arrange
        let model = EditableProductModel(product: Fixtures.productWithCustomFields)

        // Act
        let featureFlagService = MockFeatureFlagService(viewEditCustomFieldsInProductsAndOrders: true)
        let factory = ProductFormActionsFactory(product: model, formType: .edit, featureFlagService: featureFlagService)

        // Assert
        XCTAssertTrue(factory.settingsSectionActions().contains(.customFields),
                      "Custom fields row should be visible when product has an ID and existing custom fields")
    }


    func test_givenExistingProductAndEmptyCustomFields_whenCreatingActions_thenCustomFieldsRowIsInvisible() {
        // Arrange
        let model = EditableProductModel(product: Fixtures.productWithNoCustomFields)

        // Act
        let featureFlagService = MockFeatureFlagService(viewEditCustomFieldsInProductsAndOrders: true)
        let factory = ProductFormActionsFactory(product: model, formType: .edit, featureFlagService: featureFlagService)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.customFields),
                       "Custom fields row should be invisible when product has an ID but empty custom fields")
    }

    func test_givenNewProductCreation_whenCreatingActions_thenCustomFieldsRowIsInvisible() {
        // Arrange
        let model = EditableProductModel(product: Fixtures.productWithNoCustomFields)

        // Act
        let featureFlagService = MockFeatureFlagService(viewEditCustomFieldsInProductsAndOrders: true)
        let factory = ProductFormActionsFactory(product: model, formType: .add, featureFlagService: featureFlagService)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.customFields),
                       "Custom fields row should be invisible when creating a new product (no ID)")
    }
}

private extension ProductFormActionsFactory_VisibilityTests {
    enum Fixtures {
        // Price
        static let productWithPriceData = Product.fake().copy(productTypeKey: ProductType.simple.rawValue, regularPrice: "17")
        static let productWithoutPriceData = productWithPriceData.copy(regularPrice: .some(nil))
        // Inventory
        static let productWithInventoryData = Product.fake().copy(productTypeKey: ProductType.simple.rawValue, sku: "123", manageStock: true)
        static let productWithMissingInventoryData = productWithInventoryData.copy(sku: .some(nil))
        // Shipping
        static let productWithShippingData = Product.fake().copy(productTypeKey: ProductType.simple.rawValue,
                                                                 weight: "100",
                                                                 dimensions: ProductDimensions(length: "10", width: "0", height: "0"))
        static let productWithMissingShippingData = productWithShippingData.copy(weight: .some(nil),
                                                                                 dimensions: ProductDimensions(length: "", width: "", height: ""))
        // Categories
        static let productWithOneCategory = Product.fake().copy(productTypeKey: ProductType.simple.rawValue,
                                                                categories: [ProductCategory(categoryID: 0, siteID: 0, parentID: 0, name: "", slug: "")])
        static let productWithoutCategories = productWithOneCategory.copy(categories: [])
        // Short description
        static let productWithNonEmptyShortDescription = Product.fake().copy(productTypeKey: ProductType.simple.rawValue, shortDescription: "desc")
        static let productWithEmptyShortDescription = productWithNonEmptyShortDescription.copy(shortDescription: "")

        // Downloadable Files
        static let downloadableProduct = Product.fake().copy(productTypeKey: ProductType.simple.rawValue, downloadable: true)
        static let nonDownloadableProduct = downloadableProduct.copy(downloadable: false)

        // Custom fields
        static let productWithCustomFields = Product.fake().copy(customFields: [MetaData(metadataID: 1, key: "test", value: "value")])
        static let productWithNoCustomFields = Product.fake().copy(customFields: [])
    }
}
