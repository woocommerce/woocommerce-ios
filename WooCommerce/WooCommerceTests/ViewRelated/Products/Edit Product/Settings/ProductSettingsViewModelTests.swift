import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductSettingsViewModelTests: XCTestCase {

    func testOnReloadClosure() {

        let product = Product.fake().copy(slug: "this-is-a-slug",
                                          statusKey: ProductStatus.publish.rawValue,
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
        viewModel.productSettings = ProductSettings(status: product.productStatus,
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
        let product = Product.fake().copy(statusKey: ProductStatus.publish.rawValue,
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
        let product = Product.fake().copy(statusKey: ProductStatus.publish.rawValue,
                                          featured: false,
                                          catalogVisibilityKey: ProductCatalogVisibility.search.rawValue)
        let viewModel = ProductSettingsViewModel(product: product, password: nil)

        XCTAssertFalse(viewModel.hasUnsavedChanges())

        viewModel.productSettings.status = .pending
        viewModel.productSettings.featured = false
        viewModel.productSettings.password = "12345"

        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

}

private extension ProductSettingsViewModel {
    convenience init(product: Product, password: String?) {
        self.init(product: product,
                  password: password,
                  formType: .edit)
    }
}
