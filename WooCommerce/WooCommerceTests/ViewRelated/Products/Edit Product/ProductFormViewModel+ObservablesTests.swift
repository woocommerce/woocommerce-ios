import Combine
import Photos
import XCTest
import Fakes

@testable import WooCommerce
@testable import Storage
import Yosemite

/// Unit tests for observables (`observableProduct`, `productName`, `isUpdateEnabled`)
final class ProductFormViewModel_ObservablesTests: XCTestCase {
    private let defaultSiteID: Int64 = 134
    private var cancellableProduct: AnyCancellable?
    private var cancellableProductName: AnyCancellable?
    private var cancellableUpdateEnabled: AnyCancellable?
    private var cancellableVariationPrice: AnyCancellable?


    override func tearDown() {
        [cancellableProduct, cancellableProductName, cancellableUpdateEnabled, cancellableVariationPrice].forEach { cancellable in
            cancellable?.cancel()
        }
        cancellableProduct = nil
        cancellableProductName = nil
        cancellableUpdateEnabled = nil
        cancellableVariationPrice = nil

        super.tearDown()
    }

    func testObservablesFromEditActionsOfTheSameData() {
        // Arrange
        let product = Fakes.ProductFactory.productWithEditableDataFilled()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)
        let taxClass = TaxClass(siteID: product.siteID, name: "standard", slug: product.taxClass ?? "standard")
        cancellableProduct = viewModel.observableProduct.sink { _ in
            // Assert
            XCTFail("Should not be triggered from edit actions of the same data")
        }
        cancellableProductName = viewModel.productName?.sink { _ in
            // Assert
            XCTFail("Should not be triggered from edit actions of the same data")
        }
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.sink { _ in
            // Assert
            XCTFail("Should not be triggered from edit actions of the same data")
        }

        // Action
        viewModel.updateName(product.name)
        viewModel.updateDescription(product.fullDescription ?? "")
        viewModel.updateShortDescription(product.shortDescription ?? "")
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
        viewModel.updateShippingSettings(weight: product.weight,
                                         dimensions: product.dimensions,
                                         shippingClass: product.shippingClass,
                                         shippingClassID: product.shippingClassID)
        viewModel.updateProductCategories(product.categories)
        viewModel.updateProductTags(product.tags)
        viewModel.updateDownloadableFiles(downloadableFiles: product.downloads,
                                          downloadLimit: product.downloadLimit,
                                          downloadExpiry: product.downloadExpiry)
    }

    /// When only product name is updated, the product name observable should be triggered but no the product observable.
    func testObservablesFromEditingProductName() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)
        var isProductUpdated: Bool?
        cancellableProduct = viewModel.observableProduct.sink { product in
            isProductUpdated = true
        }

        var updatedProductName: String?
        let expectationForProductName = self.expectation(description: "Product name updates")
        expectationForProductName.expectedFulfillmentCount = 1
        cancellableProductName = viewModel.productName?.sink { productName in
            updatedProductName = productName
            expectationForProductName.fulfill()
        }

        var updatedUpdateEnabled: Bool?
        let expectationForUpdateEnabled = self.expectation(description: "Update enabled updates")
        expectationForUpdateEnabled.expectedFulfillmentCount = 1
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.sink { isUpdateEnabled in
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
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)
        var isProductUpdated: Bool?
        cancellableProduct = viewModel.observableProduct.sink { product in
            isProductUpdated = true
        }

        var updatedProductName: String?
        cancellableProductName = viewModel.productName?.sink { productName in
            updatedProductName = productName
        }

        var updatedUpdateEnabled: Bool?
        let expectationForUpdateEnabled = self.expectation(description: "Update enabled updates")
        expectationForUpdateEnabled.expectedFulfillmentCount = 1
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.sink { isUpdateEnabled in
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
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)
        // The password is set from a separate DotCom API.
        viewModel.resetPassword("134")

        var isProductUpdated: Bool?
        cancellableProduct = viewModel.observableProduct.sink { product in
            isProductUpdated = true
        }

        var updatedProductName: String?
        cancellableProductName = viewModel.productName?.sink { productName in
            updatedProductName = productName
        }

        var updatedUpdateEnabled: Bool?
        let expectationForUpdateEnabled = self.expectation(description: "Update enabled updates")
        expectationForUpdateEnabled.expectedFulfillmentCount = 2
        // The update enabled boolean should be set to true from the password change, and then back to false after resetting with
        // the same password after remote update.
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.sink { isUpdateEnabled in
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
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)
        var isProductUpdated: Bool?
        cancellableProduct = viewModel.observableProduct.sink { product in
            isProductUpdated = true
        }

        var updatedProductName: String?
        cancellableProductName = viewModel.productName?.sink { productName in
            updatedProductName = productName
        }

        var updatedUpdateEnabled: Bool?
        let expectationForUpdateEnabled = self.expectation(description: "Update enabled updates")
        expectationForUpdateEnabled.expectedFulfillmentCount = 1
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.sink { isUpdateEnabled in
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

    func test_adding_variation_price_triggers_a_price_update_and_removes_noPriceWarning_action() {
        // Given
        let mockStorage = MockStorageManager()
        let productID: Int64 = 123
        let variationID: Int64 = 256
        let product = Product.fake().copy(siteID: defaultSiteID, productID: productID, productTypeKey: ProductType.variable.rawValue, variations: [variationID])
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model, formType: .edit, productImageActionHandler: productImageActionHandler, storageManager: mockStorage)

        XCTAssertTrue(viewModel.actionsFactory.settingsSectionActions().contains(.noPriceWarning))

        // When
        let priceUpdated: Bool = waitFor { promise in
            self.cancellableVariationPrice = viewModel.newVariationsPrice.sink { promise(true) }

            let newVariation = ProductVariation.fake().copy(siteID: self.defaultSiteID, productID: productID,
                                                            productVariationID: variationID,
                                                            regularPrice: "10.2")
            mockStorage.insertSampleProductVariation(readOnlyProductVariation: newVariation, on: product)
        }

        // Then
        XCTAssertTrue(priceUpdated)
        XCTAssertFalse(viewModel.actionsFactory.settingsSectionActions().contains(.noPriceWarning))
    }

    func test_removing_variation_price_triggers_a_price_update_and_adds_noPriceWarning_action() {
        // Given
        let productID: Int64 = 123
        let product = Product.fake().copy(siteID: defaultSiteID, productID: productID, productTypeKey: ProductType.variable.rawValue)

        let variation = ProductVariation.fake().copy(siteID: self.defaultSiteID, productID: productID, productVariationID: 234, regularPrice: "10.2")
        let mockStorage = MockStorageManager()
        mockStorage.insertSampleProductVariation(readOnlyProductVariation: variation, on: product)

        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model, formType: .edit, productImageActionHandler: productImageActionHandler, storageManager: mockStorage)

        XCTAssertFalse(viewModel.actionsFactory.settingsSectionActions().contains(.noPriceWarning))

        // When
        let priceUpdated: Bool = waitFor { promise in
            self.cancellableVariationPrice = viewModel.newVariationsPrice.sink { promise(true) }

            let newVariation = variation.copy(regularPrice: "")
            mockStorage.insertSampleProductVariation(readOnlyProductVariation: newVariation, on: product)
        }

        // Then
        XCTAssertTrue(priceUpdated)
        XCTAssertTrue(viewModel.actionsFactory.settingsSectionActions().contains(.noPriceWarning))
    }
}
