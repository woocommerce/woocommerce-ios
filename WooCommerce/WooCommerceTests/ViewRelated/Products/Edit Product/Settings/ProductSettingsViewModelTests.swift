import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductSettingsViewModelTests: XCTestCase {

    func testOnReloadClosure() {

        let product = Product.fake().copy(slug: "this-is-a-slug",
                                          statusKey: ProductStatus.published.rawValue,
                                          featured: true,
                                          catalogVisibilityKey: ProductCatalogVisibility.search.rawValue,
                                          virtual: true,
                                          downloadable: false,
                                          reviewsAllowed: false,
                                          menuOrder: 1)
        let viewModel = ProductSettingsViewModel(product: product, password: "1234")

        // Act
        let expectation = self.expectation(description: "Wait for the view model data to be updated")

        viewModel.onReload = {
            expectation.fulfill()
        }

        // Update settings. Section data changed. This will update the view model, and will fire the `onReload` closure.
        viewModel.productSettings = ProductSettings(productType: .simple,
                                                    status: product.productStatus,
                                                    featured: true,
                                                    password: "1234",
                                                    catalogVisibility: .search,
                                                    virtual: true,
                                                    reviewsAllowed: true,
                                                    slug: "this-is-a-slug",
                                                    purchaseNote: "This is a purchase note",
                                                    menuOrder: 1,
                                                    downloadable: true)

        waitForExpectations(timeout: 1.5, handler: nil)
    }

    func testHasUnsavedChanges() {
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue,
                                          featured: false,
                                          catalogVisibilityKey: ProductCatalogVisibility.search.rawValue)
        let viewModel = ProductSettingsViewModel(product: product, password: "12345")

        XCTAssertFalse(viewModel.hasUnsavedChanges())

        viewModel.productSettings.status = .pending
        viewModel.productSettings.featured = false
        viewModel.productSettings.catalogVisibility = .search

        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testHasUnsavedChangesWithOnlyThePasswordChanged() {
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue,
                                          featured: false,
                                          catalogVisibilityKey: ProductCatalogVisibility.search.rawValue)
        let viewModel = ProductSettingsViewModel(product: product, password: nil)

        XCTAssertFalse(viewModel.hasUnsavedChanges())

        viewModel.productSettings.status = .pending
        viewModel.productSettings.featured = false
        viewModel.productSettings.password = "12345"

        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_viewmodel_has_product_type_setting_displayed_when_it_is_enabled() {
        // Given
        let product = Product.fake().copy(productTypeKey: "simple")
        let viewModel = ProductSettingsViewModel(product: product, password: nil, formType: .edit, isProductTypeSettingEnabled: true)

        // Then
        XCTAssertTrue(viewModel.productSettings.productType == .simple)
        XCTAssertFalse(viewModel.hasUnsavedChanges())
        XCTAssertTrue(viewModel.sections.first is ProductSettingsSections.ProductTypeSetting)

        // When
        viewModel.productSettings.productType = .variable

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_viewmodel_hides_product_type_setting_when_it_is_disabled() {
        // Given
        let product = Product.fake().copy(productTypeKey: "simple")
        let viewModel = ProductSettingsViewModel(product: product, password: nil, formType: .edit, isProductTypeSettingEnabled: false)

        // Then
        XCTAssertFalse(viewModel.sections.contains(where: { $0 is ProductSettingsSections.ProductTypeSetting }))
    }
}

private extension ProductSettingsViewModel {
    convenience init(product: Product, password: String?) {
        self.init(product: product,
                  password: password,
                  formType: .edit)
    }
}
