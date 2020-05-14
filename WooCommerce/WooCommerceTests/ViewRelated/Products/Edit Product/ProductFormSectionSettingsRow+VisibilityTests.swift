import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductFormSectionSettingsRow_VisibilityTests: XCTestCase {
    // MARK: - Price

    func testPriceRowIsVisibleForProductWithPriceData() {
        let product = Fixtures.productWithPriceData
        let viewModel = ProductFormSection.SettingsRow.ViewModel(icon: .plusImage, title: nil, details: nil)
        XCTAssertTrue(ProductFormSection.SettingsRow.price(viewModel: viewModel).isVisible(product: product))
    }

    func testPriceRowIsVisibleForProductWithoutPriceData() {
        let product = Fixtures.productWithoutPriceData
        let viewModel = ProductFormSection.SettingsRow.ViewModel(icon: .plusImage, title: nil, details: nil)
        XCTAssertTrue(ProductFormSection.SettingsRow.price(viewModel: viewModel).isVisible(product: product))
    }

    // MARK: - Inventory

    func testInventoryRowIsVisibleForProductWithInventoryData() {
        let product = Fixtures.productWithInventoryData
        let viewModel = ProductFormSection.SettingsRow.ViewModel(icon: .plusImage, title: nil, details: nil)
        XCTAssertTrue(ProductFormSection.SettingsRow.inventory(viewModel: viewModel).isVisible(product: product))
    }

    func testInventoryRowIsInvisibleForProductWithMissingInventoryData() {
        let product = Fixtures.productWithMissingInventoryData
        let viewModel = ProductFormSection.SettingsRow.ViewModel(icon: .plusImage, title: nil, details: nil)
        XCTAssertFalse(ProductFormSection.SettingsRow.inventory(viewModel: viewModel).isVisible(product: product))
    }

    // MARK: - Shipping

    func testShippingRowIsVisibleForProductWithShippingData() {
        let product = Fixtures.productWithShippingData
        let viewModel = ProductFormSection.SettingsRow.ViewModel(icon: .plusImage, title: nil, details: nil)
        XCTAssertTrue(ProductFormSection.SettingsRow.shipping(viewModel: viewModel).isVisible(product: product))
    }

    func testShippingRowIsInvisibleForProductWithMissingShippingData() {
        let product = Fixtures.productWithMissingShippingData
        let viewModel = ProductFormSection.SettingsRow.ViewModel(icon: .plusImage, title: nil, details: nil)
        XCTAssertFalse(ProductFormSection.SettingsRow.shipping(viewModel: viewModel).isVisible(product: product))
    }

    // MARK: - Categories

    func testCategoriesRowIsVisibleForProductWithACategory() {
        let product = Fixtures.productWithOneCategory
        let viewModel = ProductFormSection.SettingsRow.ViewModel(icon: .plusImage, title: nil, details: nil)
        XCTAssertTrue(ProductFormSection.SettingsRow.categories(viewModel: viewModel).isVisible(product: product))
    }

    func testCategoriesRowIsInvisibleForProductWithoutCategories() {
        let product = Fixtures.productWithoutCategories
        let viewModel = ProductFormSection.SettingsRow.ViewModel(icon: .plusImage, title: nil, details: nil)
        XCTAssertFalse(ProductFormSection.SettingsRow.categories(viewModel: viewModel).isVisible(product: product))
    }

    // MARK: - Brief description

    func testBriefDescriptionRowIsVisibleForProductWithNonEmptyBriefDescription() {
        let product = Fixtures.productWithNonEmptyBriefDescription
        let viewModel = ProductFormSection.SettingsRow.ViewModel(icon: .plusImage, title: nil, details: nil)
        XCTAssertTrue(ProductFormSection.SettingsRow.briefDescription(viewModel: viewModel).isVisible(product: product))
    }

    func testBriefDescriptionRowIsInvisibleForProductWithoutBriefDescription() {
        let product = Fixtures.productWithEmptyBriefDescription
        let viewModel = ProductFormSection.SettingsRow.ViewModel(icon: .plusImage, title: nil, details: nil)
        XCTAssertFalse(ProductFormSection.SettingsRow.briefDescription(viewModel: viewModel).isVisible(product: product))
    }
}

private extension ProductFormSectionSettingsRow_VisibilityTests {
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
