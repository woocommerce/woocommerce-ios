import XCTest

@testable import WooCommerce
import Yosemite

/// Unit tests for update functions in `ProductVariationFormViewModel`.
final class ProductVariationFormViewModel_UpdatesTests: XCTestCase {
    func testUpdatingDescription() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        let newDescription = "<p> cool product </p>"
        viewModel.updateDescription(newDescription)

        // Assert
        XCTAssertEqual(viewModel.productModel.description, newDescription)
    }

    func testUpdatingShippingSettings() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        let newWeight = "9999.88"
        let newDimensions = ProductDimensions(length: "122", width: "333", height: "")
        let newShippingClass = ProductShippingClass(count: 2020,
                                                    descriptionHTML: "Arriving in 2 days!",
                                                    name: "2 Days",
                                                    shippingClassID: 2022,
                                                    siteID: productVariation.siteID,
                                                    slug: "2-days")
        viewModel.updateShippingSettings(weight: newWeight,
                                         dimensions: newDimensions,
                                         shippingClass: newShippingClass.slug,
                                         shippingClassID: newShippingClass.shippingClassID)

        // Assert
        XCTAssertEqual(viewModel.productModel.description, productVariation.description)
        XCTAssertEqual(viewModel.productModel.weight, newWeight)
        XCTAssertEqual(viewModel.productModel.dimensions, newDimensions)
        XCTAssertEqual(viewModel.productModel.shippingClass, newShippingClass.slug)
        XCTAssertEqual(viewModel.productModel.shippingClassID, newShippingClass.shippingClassID)
        XCTAssertEqual(viewModel.productModel.shippingClass, newShippingClass.slug)
    }

    func testUpdatingPriceSettings() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        let newRegularPrice = "32.45"
        let newSalePrice = "20.00"
        let newDateOnSaleStart = Date()
        let newDateOnSaleEnd = newDateOnSaleStart.addingTimeInterval(86400)
        let newTaxStatus = ProductTaxStatus.taxable
        let newTaxClass = TaxClass(siteID: productVariation.siteID, name: "Reduced rate", slug: "reduced-rate")
        viewModel.updatePriceSettings(regularPrice: newRegularPrice,
                                      salePrice: newSalePrice,
                                      dateOnSaleStart: newDateOnSaleStart,
                                      dateOnSaleEnd: newDateOnSaleEnd,
                                      taxStatus: newTaxStatus,
                                      taxClass: newTaxClass)

        // Assert
        XCTAssertEqual(viewModel.productModel.regularPrice, newRegularPrice)
        XCTAssertEqual(viewModel.productModel.salePrice, newSalePrice)
        XCTAssertEqual(viewModel.productModel.dateOnSaleStart, newDateOnSaleStart)
        XCTAssertEqual(viewModel.productModel.dateOnSaleEnd, newDateOnSaleEnd)
        XCTAssertEqual(viewModel.productModel.taxStatusKey, newTaxStatus.rawValue)
        XCTAssertEqual(viewModel.productModel.taxClass, newTaxClass.slug)
    }

    func testUpdatingInventorySettings() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        let newSKU = "94115"
        let newManageStock = !productVariation.manageStock
        let newStockQuantity: Decimal = 17
        let newBackordersSetting = ProductBackordersSetting.allowedAndNotifyCustomer
        let newStockStatus = ProductStockStatus.onBackOrder
        viewModel.updateInventorySettings(sku: newSKU,
                                          manageStock: newManageStock,
                                          soldIndividually: nil,
                                          stockQuantity: newStockQuantity,
                                          backordersSetting: newBackordersSetting,
                                          stockStatus: newStockStatus)

        // Assert
        XCTAssertEqual(viewModel.productModel.sku, newSKU)
        XCTAssertEqual(viewModel.productModel.manageStock, newManageStock)
        XCTAssertEqual(viewModel.productModel.stockQuantity, newStockQuantity)
        XCTAssertEqual(viewModel.productModel.backordersSetting, newBackordersSetting)
        XCTAssertEqual(viewModel.productModel.stockStatus, newStockStatus)
    }

    func testUpdatingImages() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        let newImage = ProductImage(imageID: 17,
                                    dateCreated: Date(),
                                    dateModified: Date(),
                                    src: "https://somewebsite.com/shirt.jpg",
                                    name: "Tshirt",
                                    alt: "")
        let newImages = [newImage]
        viewModel.updateImages(newImages)

        // Assert
        XCTAssertEqual(viewModel.productModel.images, newImages)
    }

    func test_updating_attributes() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        let newAttribute = ProductVariationAttribute(id: 1, name: "Color", option: "Blue")
        let newAttributes = [newAttribute]
        viewModel.updateVariationAttributes(newAttributes)

        //Assert
        XCTAssertEqual(viewModel.productModel.productVariation.attributes, newAttributes)
    }

    func testDisablingAVariationUpdatesItsStatusFromPublishToPrivate() {
        // Arrange
        let productVariation = MockProductVariation().productVariation().copy(status: .publish)
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updateStatus(false)

        // Assert
        XCTAssertEqual(viewModel.productModel.status, .privateStatus)
    }

    func testEnablingAVariationUpdatesItsStatusFromPrivateToPublish() {
        // Arrange
        let productVariation = MockProductVariation().productVariation().copy(status: .privateStatus)
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updateStatus(true)

        // Assert
        XCTAssertEqual(viewModel.productModel.status, .publish)
    }

    // MARK: - Deletion

    func test_deleting_variation_successfully_returns_success_result() throws {
        // Given
        let sampleProductVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: sampleProductVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)

        let mockStoresManager = MockStoresManager(sessionManager: SessionManager.testingInstance)
        mockDeleteVariation(storesManager: mockStoresManager, result: .success(()))

        let viewModel = ProductVariationFormViewModel(productVariation: model,
                                                      productImageActionHandler: productImageActionHandler,
                                                      storesManager: mockStoresManager)

        let expectationForDeletionCallback = expectation(description: "Deletion callback")
        viewModel.onVariationDeletion = { _ in
            expectationForDeletionCallback.fulfill()
        }

        // When
        let result: Result<Void, ProductUpdateError> = waitFor { promise in
            viewModel.deleteProductRemotely { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        wait(for: [expectationForDeletionCallback], timeout: Constants.expectationTimeout)
        XCTAssertEqual(mockStoresManager.receivedActions.count, 1)
        XCTAssertNotNil(mockStoresManager.receivedActions[0] as? ProductVariationAction)
    }

    func test_deleting_variation_failure_returns_error() {
        // Given
        let sampleProductVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: sampleProductVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)

        let mockStoresManager = MockStoresManager(sessionManager: SessionManager.testingInstance)
        mockDeleteVariation(storesManager: mockStoresManager, result: .failure(.unexpected))

        let viewModel = ProductVariationFormViewModel(productVariation: model,
                                                      productImageActionHandler: productImageActionHandler,
                                                      storesManager: mockStoresManager)
        viewModel.onVariationDeletion = { _ in
            XCTFail("Deletion callback shouldn't be called on error")
        }

        // When
        let result: Result<Void, ProductUpdateError> = waitFor { promise in
            viewModel.deleteProductRemotely { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(mockStoresManager.receivedActions.count, 1)
        XCTAssertNotNil(mockStoresManager.receivedActions[0] as? ProductVariationAction)
    }
}

private extension ProductVariationFormViewModel_UpdatesTests {
    func mockDeleteVariation(storesManager: MockStoresManager, result: Result<Void, ProductUpdateError>) {
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            if case let ProductVariationAction.deleteProductVariation(_, onCompletion) = action {
                onCompletion(result)
            }
        }
    }
}
