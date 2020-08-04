import Photos
import XCTest

@testable import WooCommerce
import Yosemite

/// Unit tests for observables (`observableProduct`, `productName`, `isUpdateEnabled`)
final class ProductVariationFormViewModel_ObservablesTests: XCTestCase {
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

    func testProductVariationNameObservableIsNil() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: productVariation)

        // Action
        let viewModel = ProductVariationFormViewModel(productVariation: productVariation, productImageActionHandler: productImageActionHandler)

        // Assert
        XCTAssertNil(viewModel.productName)
    }

    func testObservablesAreNotEmittedFromEditActionsOfTheSameData() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: productVariation)
        let viewModel = ProductVariationFormViewModel(productVariation: productVariation, productImageActionHandler: productImageActionHandler)
        cancellableProduct = viewModel.observableProduct.subscribe { _ in
            // Assert
            XCTFail("Should not be triggered from edit actions of the same data")
        }
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.subscribe { _ in
            // Assert
            XCTFail("Should not be triggered from edit actions of the same data")
        }

        // Action
        viewModel.updateImages(productVariation.images)
        viewModel.updateDescription(productVariation.description ?? "")
        viewModel.updatePriceSettings(regularPrice: productVariation.regularPrice,
                                      salePrice: productVariation.salePrice,
                                      dateOnSaleStart: productVariation.dateOnSaleStart,
                                      dateOnSaleEnd: productVariation.dateOnSaleEnd,
                                      taxStatus: productVariation.productTaxStatus,
                                      taxClass: nil)
        viewModel.updateInventorySettings(sku: productVariation.sku,
                                          manageStock: productVariation.manageStock,
                                          soldIndividually: nil,
                                          stockQuantity: productVariation.stockQuantity,
                                          backordersSetting: productVariation.backordersSetting,
                                          stockStatus: productVariation.stockStatus)
        viewModel.updateShippingSettings(weight: productVariation.weight, dimensions: productVariation.dimensions, shippingClass: nil)
    }

    func testObservablesFromUploadingAnImage() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: productVariation)
        let viewModel = ProductVariationFormViewModel(productVariation: productVariation, productImageActionHandler: productImageActionHandler)
        var isProductUpdated: Bool?
        cancellableProduct = viewModel.observableProduct.subscribe { product in
            isProductUpdated = true
        }

        // Action
        var updatedUpdateEnabled: Bool?
        waitForExpectation { expectation in
            cancellableUpdateEnabled = viewModel.isUpdateEnabled.subscribe { isUpdateEnabled in
                updatedUpdateEnabled = isUpdateEnabled
                expectation.fulfill()
            }
            productImageActionHandler.uploadMediaAssetToSiteMediaLibrary(asset: PHAsset())
        }

        // Assert
        XCTAssertNil(isProductUpdated)
        XCTAssertEqual(updatedUpdateEnabled, true)
    }

    func testObservablesFromUpdatingAVariationSuccessfully() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: productVariation)
        let newDescription = "Woo!"
        let expectedProductVariationAfterUpdate = productVariation.copy(description: newDescription)
        let mockStoresManager = MockProductVariationStoresManager(updateResult: .success(expectedProductVariationAfterUpdate))
        let viewModel = ProductVariationFormViewModel(productVariation: productVariation,
                                                      productImageActionHandler: productImageActionHandler,
                                                      storesManager: mockStoresManager)

        var isProductUpdated: Bool?
        cancellableProduct = viewModel.observableProduct.subscribe { product in
            isProductUpdated = true
        }

        var updatedUpdateEnabled: Bool?
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.subscribe { isUpdateEnabled in
            updatedUpdateEnabled = isUpdateEnabled
        }

        // Action
        viewModel.updateDescription(newDescription)

        var updateResult: Result<ProductVariation, ProductUpdateError>?
        viewModel.updateProductRemotely { result in
            updateResult = result
        }

        // Assert
        XCTAssertEqual(viewModel.productModel, expectedProductVariationAfterUpdate)
        XCTAssertEqual(updateResult, .success(expectedProductVariationAfterUpdate))
        XCTAssertEqual(isProductUpdated, true)
        XCTAssertEqual(updatedUpdateEnabled, false)
    }

    func testObservablesFromUpdatingAVariationWithAnError() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: productVariation)
        let newDescription = "Woo!"
        let mockUpdateError = ProductUpdateError.notFoundInStorage
        let mockStoresManager = MockProductVariationStoresManager(updateResult: .failure(mockUpdateError))
        let viewModel = ProductVariationFormViewModel(productVariation: productVariation,
                                                      productImageActionHandler: productImageActionHandler,
                                                      storesManager: mockStoresManager)

        var isProductUpdated: Bool?
        cancellableProduct = viewModel.observableProduct.subscribe { product in
            isProductUpdated = true
        }

        var updatedUpdateEnabled: Bool?
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.subscribe { isUpdateEnabled in
            updatedUpdateEnabled = isUpdateEnabled
        }

        // Action
        viewModel.updateDescription(newDescription)

        var updateResult: Result<ProductVariation, ProductUpdateError>?
        viewModel.updateProductRemotely { result in
            updateResult = result
        }

        // Assert
        XCTAssertEqual(viewModel.productModel, productVariation.copy(description: newDescription))
        XCTAssertEqual(updateResult, .failure(mockUpdateError))
        XCTAssertEqual(isProductUpdated, true)
        XCTAssertEqual(updatedUpdateEnabled, true)
    }
}
