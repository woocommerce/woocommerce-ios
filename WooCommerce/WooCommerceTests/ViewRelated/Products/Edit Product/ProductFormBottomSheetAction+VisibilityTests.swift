import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductFormBottomSheetAction_VisibilityTests: XCTestCase {
    // MARK: - Inventory

    func testInventoryActionIsVisibleForProductWithMissingInventoryData() {
        let product = Fixtures.productWithMissingInventoryData
        XCTAssertTrue(ProductFormBottomSheetAction.editInventorySettings.isVisible(product: product))
    }

    func testInventoryRowIsInvisibleForProductWithMissingInventoryData() {
        let product = Fixtures.productWithInventoryData
        XCTAssertFalse(ProductFormBottomSheetAction.editInventorySettings.isVisible(product: product))
    }

    // MARK: - Shipping

    func testShippingActionIsVisibleForProductWithMissingShippingData() {
        let product = Fixtures.productWithMissingShippingData
        XCTAssertTrue(ProductFormBottomSheetAction.editShippingSettings.isVisible(product: product))
    }

    func testShippingActionIsInvisibleForProductWithShippingData() {
        let product = Fixtures.productWithShippingData
        XCTAssertFalse(ProductFormBottomSheetAction.editShippingSettings.isVisible(product: product))
    }

    // MARK: - Categories

    func testCategoriesActionIsVisibleForProductWithoutCategories() {
        let product = Fixtures.productWithoutCategories
        XCTAssertTrue(ProductFormBottomSheetAction.editCategories.isVisible(product: product))
    }

    func testCategoriesActionIsInvisibleForProductWithACategory() {
        let product = Fixtures.productWithOneCategory
        XCTAssertFalse(ProductFormBottomSheetAction.editCategories.isVisible(product: product))
    }

    // MARK: - Brief description

    func testBriefDescriptionActionIsVisibleForProductWithoutBriefDescription() {
        let product = Fixtures.productWithEmptyBriefDescription
        XCTAssertTrue(ProductFormBottomSheetAction.editBriefDescription.isVisible(product: product))
    }

    func testBriefDescriptionActionIsInvisibleForProductWithNonEmptyBriefDescription() {
        let product = Fixtures.productWithNonEmptyBriefDescription
        XCTAssertFalse(ProductFormBottomSheetAction.editBriefDescription.isVisible(product: product))
    }
}

private extension ProductFormBottomSheetAction_VisibilityTests {
    enum Fixtures {
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
