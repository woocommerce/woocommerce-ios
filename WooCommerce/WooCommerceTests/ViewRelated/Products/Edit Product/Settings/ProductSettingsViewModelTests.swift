import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductSettingsViewModelTests: XCTestCase {

    private var storesManager: MockStoresManager!
    private var storageManager: MockStorageManager!
    private let siteID: Int64 = 123
    private let pluginName = "WooCommerce"

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: SessionManager.testingInstance)
        storesManager.sessionManager.setStoreId(siteID)
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storesManager = nil
        storageManager = nil
        super.tearDown()
    }

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

    func test_HasUnsavedChanges_with_WC_below_8_1() {
        // Given
        let activePlugin = SystemPlugin.fake().copy(siteID: siteID,
                                                    name: pluginName,
                                                    version: "8.0",
                                                    active: true)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: activePlugin)

        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue,
                                          featured: false,
                                          catalogVisibilityKey: ProductCatalogVisibility.search.rawValue)
        let viewModel = ProductSettingsViewModel(product: product, password: "12345")

        XCTAssertFalse(viewModel.hasUnsavedChanges())

        // When
        viewModel.productSettings.status = .pending
        viewModel.productSettings.featured = false
        viewModel.productSettings.catalogVisibility = .search

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_hasUnsavedChanges_with_WC_above_8_1() {
        // Given
        let activePlugin = SystemPlugin.fake().copy(siteID: siteID,
                                                    name: pluginName,
                                                    version: "9.0",
                                                    active: true)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: activePlugin)

        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue,
                                          featured: false,
                                          catalogVisibilityKey: ProductCatalogVisibility.search.rawValue)
        let viewModel = ProductSettingsViewModel(product: product, password: "12345")

        XCTAssertFalse(viewModel.hasUnsavedChanges())

        // When
        viewModel.productSettings.status = .pending
        viewModel.productSettings.featured = false
        viewModel.productSettings.catalogVisibility = .search

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_hasUnsavedChanges_with_only_the_password_changed_with_WC_below_8_1() {
        // Given
        let activePlugin = SystemPlugin.fake().copy(siteID: siteID,
                                                    name: pluginName,
                                                    version: "8.0",
                                                    active: true)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: activePlugin)

        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue,
                                          featured: false,
                                          catalogVisibilityKey: ProductCatalogVisibility.search.rawValue)
        let viewModel = ProductSettingsViewModel(product: product, password: nil)

        XCTAssertFalse(viewModel.hasUnsavedChanges())

        // When
        viewModel.productSettings.status = .pending
        viewModel.productSettings.featured = false
        viewModel.productSettings.password = "12345"

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_hasUnsavedChanges_with_only_the_password_changed_with_WC_above_8_1() {
        // Given
        let activePlugin = SystemPlugin.fake().copy(siteID: siteID,
                                                    name: pluginName,
                                                    version: "9.0",
                                                    active: true)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: activePlugin)

        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue,
                                          featured: false,
                                          catalogVisibilityKey: ProductCatalogVisibility.search.rawValue)
        let viewModel = ProductSettingsViewModel(product: product, password: nil)

        XCTAssertFalse(viewModel.hasUnsavedChanges())

        // When
        viewModel.productSettings.status = .pending
        viewModel.productSettings.featured = false
        viewModel.productSettings.password = "12345"

        // Then
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
