import Combine
import Photos
import XCTest

@testable import WooCommerce
import Yosemite

/// Unit tests for observables (`observableProduct`, `productName`, `isUpdateEnabled`)
final class ProductVariationFormViewModel_ObservablesTests: XCTestCase {
    private let defaultSiteID: Int64 = 134
    private var cancellableProduct: AnyCancellable?
    private var cancellableProductName: AnyCancellable?
    private var cancellableUpdateEnabled: AnyCancellable?

    override func tearDown() {
        [cancellableProduct, cancellableProductName, cancellableUpdateEnabled].forEach { cancellable in
            cancellable?.cancel()
        }
        cancellableProduct = nil
        cancellableProductName = nil
        cancellableUpdateEnabled = nil

        super.tearDown()
    }

    func testProductVariationNameObservableIsNil() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)

        // Action
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Assert
        XCTAssertNil(viewModel.productName)
    }

    func testObservablesAreNotEmittedFromEditActionsOfTheSameData() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)
        cancellableProduct = viewModel.observableProduct.sink { _ in
            // Assert
            XCTFail("Should not be triggered from edit actions of the same data")
        }
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.sink { _ in
            // Assert
            XCTFail("Should not be triggered from edit actions of the same data")
        }

        // Action
        viewModel.updateImages(model.images)
        viewModel.updateDescription(productVariation.description ?? "")
        viewModel.updatePriceSettings(regularPrice: productVariation.regularPrice,
                                      subscriptionPeriod: productVariation.subscription?.period,
                                      subscriptionPeriodInterval: productVariation.subscription?.periodInterval,
                                      subscriptionSignupFee: productVariation.subscription?.signUpFee,
                                      salePrice: productVariation.salePrice,
                                      dateOnSaleStart: productVariation.dateOnSaleStart,
                                      dateOnSaleEnd: productVariation.dateOnSaleEnd,
                                      taxStatus: model.productTaxStatus,
                                      taxClass: nil)
        viewModel.updateInventorySettings(sku: productVariation.sku,
                                          manageStock: productVariation.manageStock,
                                          soldIndividually: nil,
                                          stockQuantity: productVariation.stockQuantity,
                                          backordersSetting: model.backordersSetting,
                                          stockStatus: productVariation.stockStatus)
        viewModel.updateShippingSettings(weight: productVariation.weight, dimensions: productVariation.dimensions, shippingClass: nil, shippingClassID: nil)
    }

    func testObservablesFromUploadingAnImage() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let mockProductImageUploader = MockProductImageUploader()
        mockProductImageUploader.whenHasUnsavedChangesOnImagesIsCalled(thenReturn: true)
        let viewModel = ProductVariationFormViewModel(
            productVariation: model,
            productImageActionHandler: productImageActionHandler,
            productImagesUploader: mockProductImageUploader)

        var isProductUpdated: Bool?
        cancellableProduct = viewModel.observableProduct.sink { product in
            isProductUpdated = true
        }

        // Action
        var updatedUpdateEnabled: Bool?
        waitForExpectation { expectation in
            cancellableUpdateEnabled = viewModel.isUpdateEnabled.sink { isUpdateEnabled in
                updatedUpdateEnabled = isUpdateEnabled
                expectation.fulfill()
            }
            productImageActionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: PHAsset()))
        }

        // Assert
        XCTAssertNil(isProductUpdated)
        XCTAssertEqual(updatedUpdateEnabled, true)
    }

    func testObservablesFromUpdatingAVariationSuccessfully() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let newDescription = "Woo!"
        let expectedProductVariationAfterUpdate = productVariation.copy(description: newDescription)
        let expectedModelAfterUpdate = EditableProductVariationModel(productVariation: expectedProductVariationAfterUpdate)
        let mockStoresManager = MockProductVariationStoresManager(updateResult: .success(expectedProductVariationAfterUpdate))
        let viewModel = ProductVariationFormViewModel(productVariation: model,
                                                      productImageActionHandler: productImageActionHandler,
                                                      storesManager: mockStoresManager)

        var isProductUpdated: Bool?
        cancellableProduct = viewModel.observableProduct.sink { product in
            isProductUpdated = true
        }

        var updatedUpdateEnabled: Bool?
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.sink { isUpdateEnabled in
            updatedUpdateEnabled = isUpdateEnabled
        }

        // Action
        viewModel.updateDescription(newDescription)

        var updateResult: Result<EditableProductVariationModel, ProductUpdateError>?
        viewModel.saveProductRemotely(status: nil) { result in
            updateResult = result
        }

        // Assert
        XCTAssertEqual(viewModel.productModel, expectedModelAfterUpdate)
        XCTAssertEqual(updateResult, .success(expectedModelAfterUpdate))
        XCTAssertEqual(isProductUpdated, true)
        XCTAssertEqual(updatedUpdateEnabled, false)
    }

    func testObservablesFromUpdatingAVariationWithAnError() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let newDescription = "Woo!"
        let mockUpdateError = ProductUpdateError.notFoundInStorage
        let mockStoresManager = MockProductVariationStoresManager(updateResult: .failure(mockUpdateError))
        let viewModel = ProductVariationFormViewModel(productVariation: model,
                                                      productImageActionHandler: productImageActionHandler,
                                                      storesManager: mockStoresManager)

        var isProductUpdated: Bool?
        cancellableProduct = viewModel.observableProduct.sink { product in
            isProductUpdated = true
        }

        var updatedUpdateEnabled: Bool?
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.sink { isUpdateEnabled in
            updatedUpdateEnabled = isUpdateEnabled
        }

        // Action
        viewModel.updateDescription(newDescription)

        var updateResult: Result<EditableProductVariationModel, ProductUpdateError>?
        viewModel.saveProductRemotely(status: nil) { result in
            updateResult = result
        }

        // Assert
        let expectedModelAfterUpdate = EditableProductVariationModel(productVariation: productVariation.copy(description: newDescription))
        XCTAssertEqual(viewModel.productModel, expectedModelAfterUpdate)
        XCTAssertEqual(updateResult, .failure(mockUpdateError))
        XCTAssertEqual(isProductUpdated, true)
        XCTAssertEqual(updatedUpdateEnabled, true)
    }
}
