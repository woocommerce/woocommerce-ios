import Photos
import XCTest

@testable import WooCommerce
import Yosemite

/// Unit tests for observables (`observableProduct`, `productName`, `isUpdateEnabled`)
final class ProductFormViewModel_ObservablesTests: XCTestCase {
    private let defaultSiteID: Int64 = 134
    private var cancellableProduct: ObservationToken?
    private var cancellableProductName: ObservationToken?
    private var cancellableUpdateEnabled: ObservationToken?

    override func tearDown() {
        [cancellableProduct, cancellableProductName, cancellableUpdateEnabled].forEach { cancellable in
            cancellable?.cancel()
        }
        cancellableProduct = nil
        cancellableProductName = nil
        cancellableUpdateEnabled = nil

        super.tearDown()
    }

    func testObservablesFromEditActionsOfTheSameData() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)
        let taxClass = TaxClass(siteID: product.siteID, name: "standard", slug: product.taxClass ?? "standard")
        cancellableProduct = viewModel.observableProduct.subscribe { _ in
            // Assert
            XCTFail("Should not be triggered from edit actions of the same data")
        }
        cancellableProductName = viewModel.productName?.subscribe { _ in
            // Assert
            XCTFail("Should not be triggered from edit actions of the same data")
        }
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.subscribe { _ in
            // Assert
            XCTFail("Should not be triggered from edit actions of the same data")
        }

        // Action
        viewModel.updateName(product.name)
        viewModel.updateDescription(product.fullDescription ?? "")
        viewModel.updateBriefDescription(product.briefDescription ?? "")
        viewModel.updateProductSettings(ProductSettings(from: product, password: nil))
        viewModel.updatePriceSettings(regularPrice: product.regularPrice,
                                      salePrice: product.salePrice,
                                      dateOnSaleStart: product.dateOnSaleStart,
                                      dateOnSaleEnd: product.dateOnSaleEnd,
                                      taxStatus: product.productTaxStatus,
                                      taxClass: taxClass)
        viewModel.updateInventorySettings(sku: product.sku,
                                          manageStock: product.manageStock,
                                          soldIndividually: product.soldIndividually,
                                          stockQuantity: product.stockQuantity,
                                          backordersSetting: product.backordersSetting,
                                          stockStatus: product.productStockStatus)
        viewModel.updateShippingSettings(weight: product.weight, dimensions: product.dimensions, shippingClass: product.productShippingClass)
        viewModel.updateProductCategories(product.categories)
        viewModel.updateProductTags(product.tags)
    }

    /// When only product name is updated, the product name observable should be triggered but no the product observable.
    func testObservablesFromEditingProductName() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)
        var isProductUpdated: Bool?
        cancellableProduct = viewModel.observableProduct.subscribe { product in
            isProductUpdated = true
        }

        var updatedProductName: String?
        let expectationForProductName = self.expectation(description: "Product name updates")
        expectationForProductName.expectedFulfillmentCount = 1
        cancellableProductName = viewModel.productName?.subscribe { productName in
            updatedProductName = productName
            expectationForProductName.fulfill()
        }

        var updatedUpdateEnabled: Bool?
        let expectationForUpdateEnabled = self.expectation(description: "Update enabled updates")
        expectationForUpdateEnabled.expectedFulfillmentCount = 1
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.subscribe { isUpdateEnabled in
            updatedUpdateEnabled = isUpdateEnabled
            expectationForUpdateEnabled.fulfill()
        }

        // Action
        let newProductName = "this new product name"
        viewModel.updateName(newProductName)

        // Assert
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
        XCTAssertNil(isProductUpdated)
        XCTAssertEqual(updatedProductName, newProductName)
        XCTAssertEqual(updatedUpdateEnabled, true)
    }

    /// When only product password is updated, only the update enabled boolean should be triggered.
    func testObservablesFromEditingProductPassword() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)
        var isProductUpdated: Bool?
        cancellableProduct = viewModel.observableProduct.subscribe { product in
            isProductUpdated = true
        }

        var updatedProductName: String?
        cancellableProductName = viewModel.productName?.subscribe { productName in
            updatedProductName = productName
        }

        var updatedUpdateEnabled: Bool?
        let expectationForUpdateEnabled = self.expectation(description: "Update enabled updates")
        expectationForUpdateEnabled.expectedFulfillmentCount = 1
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.subscribe { isUpdateEnabled in
            updatedUpdateEnabled = isUpdateEnabled
            expectationForUpdateEnabled.fulfill()
        }

        // Action
        let settings = ProductSettings(from: product, password: "secret secret")
        viewModel.updateProductSettings(settings)

        // Assert
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
        XCTAssertNil(isProductUpdated)
        XCTAssertNil(updatedProductName)
        XCTAssertEqual(updatedUpdateEnabled, true)
    }

    func testObservablesFromUpdatingProductPasswordRemotely() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)
        // The password is set from a separate DotCom API.
        viewModel.resetPassword("134")

        var isProductUpdated: Bool?
        cancellableProduct = viewModel.observableProduct.subscribe { product in
            isProductUpdated = true
        }

        var updatedProductName: String?
        cancellableProductName = viewModel.productName?.subscribe { productName in
            updatedProductName = productName
        }

        var updatedUpdateEnabled: Bool?
        let expectationForUpdateEnabled = self.expectation(description: "Update enabled updates")
        expectationForUpdateEnabled.expectedFulfillmentCount = 2
        // The update enabled boolean should be set to true from the password change, and then back to false after resetting with
        // the same password after remote update.
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.subscribe { isUpdateEnabled in
            updatedUpdateEnabled = isUpdateEnabled
            expectationForUpdateEnabled.fulfill()
        }

        // Action
        let newPassword = "secret secret"
        let settings = ProductSettings(from: product, password: newPassword)
        viewModel.updateProductSettings(settings)
        viewModel.resetPassword(newPassword)

        // Assert
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
        XCTAssertNil(isProductUpdated)
        XCTAssertNil(updatedProductName)
        XCTAssertEqual(updatedUpdateEnabled, false)
    }

    func testObservablesFromUploadingAnImage() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)
        var isProductUpdated: Bool?
        cancellableProduct = viewModel.observableProduct.subscribe { product in
            isProductUpdated = true
        }

        var updatedProductName: String?
        cancellableProductName = viewModel.productName?.subscribe { productName in
            updatedProductName = productName
        }

        var updatedUpdateEnabled: Bool?
        let expectationForUpdateEnabled = self.expectation(description: "Update enabled updates")
        expectationForUpdateEnabled.expectedFulfillmentCount = 1
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.subscribe { isUpdateEnabled in
            updatedUpdateEnabled = isUpdateEnabled
            expectationForUpdateEnabled.fulfill()
        }

        // Action
        productImageActionHandler.uploadMediaAssetToSiteMediaLibrary(asset: PHAsset())

        // Assert
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
        XCTAssertNil(isProductUpdated)
        XCTAssertNil(updatedProductName)
        XCTAssertEqual(updatedUpdateEnabled, true)
    }
}
