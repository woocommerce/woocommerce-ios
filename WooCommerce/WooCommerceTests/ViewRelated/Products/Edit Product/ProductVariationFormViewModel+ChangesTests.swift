import Photos
import XCTest

@testable import WooCommerce
import Yosemite

/// Unit tests for unsaved changes (`hasUnsavedChanges`, `hasProductChanged`, `hasPasswordChanged`)
final class ProductVariationFormViewModel_ChangesTests: XCTestCase {
    private let defaultSiteID: Int64 = 134

    func testProductVariationHasNoChangesFromEditActionsOfTheSameData() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updateImages(model.images)
        viewModel.updateDescription(productVariation.description ?? "")
        viewModel.updatePriceSettings(regularPrice: productVariation.regularPrice,
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
        viewModel.updateShippingSettings(weight: productVariation.weight, dimensions: productVariation.dimensions, shippingClass: nil)

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
        XCTAssertFalse(viewModel.hasProductChanged())
        XCTAssertFalse(viewModel.hasPasswordChanged())
    }

    func testProductVariationHasUnsavedChangesFromUploadingAnImage() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        waitForExpectation { expectation in
            productImageActionHandler.addUpdateObserver(self) { statuses in
                if statuses.productImageStatuses.isNotEmpty {
                    expectation.fulfill()
                }
            }
            productImageActionHandler.uploadMediaAssetToSiteMediaLibrary(asset: PHAsset())
        }

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertFalse(viewModel.hasProductChanged())
        XCTAssertFalse(viewModel.hasPasswordChanged())
    }

    func testProductVariationHasUnsavedChangesFromEditingImages() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        let productImage = ProductImage(imageID: 6,
                                        dateCreated: Date(),
                                        dateModified: Date(),
                                        src: "",
                                        name: "woo",
                                        alt: nil)
        viewModel.updateImages([productImage])

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertTrue(viewModel.hasProductChanged())
        XCTAssertFalse(viewModel.hasPasswordChanged())
    }

    func testProductVariationHasUnsavedChangesFromEditingDescription() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updateDescription("Another way to describe the product?")

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertTrue(viewModel.hasProductChanged())
        XCTAssertFalse(viewModel.hasPasswordChanged())
    }

    func testProductVariationHasUnsavedChangesFromEditingPriceSettings() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updatePriceSettings(regularPrice: "999999", salePrice: "888888", dateOnSaleStart: nil, dateOnSaleEnd: nil, taxStatus: .none, taxClass: nil)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertTrue(viewModel.hasProductChanged())
        XCTAssertFalse(viewModel.hasPasswordChanged())
    }

    func testProductVariationHasUnsavedChangesFromEditingInventorySettings() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updateInventorySettings(sku: "", manageStock: false, soldIndividually: nil, stockQuantity: 888888, backordersSetting: nil, stockStatus: nil)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertTrue(viewModel.hasProductChanged())
        XCTAssertFalse(viewModel.hasPasswordChanged())
    }

    func testProductVariationHasUnsavedChangesFromEditingShippingSettings() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updateShippingSettings(weight: "88888", dimensions: productVariation.dimensions, shippingClass: nil)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertTrue(viewModel.hasProductChanged())
        XCTAssertFalse(viewModel.hasPasswordChanged())
    }
}

// Helper in unit tests
extension EditableProductVariationModel {
    convenience init(productVariation: ProductVariation) {
        self.init(productVariation: productVariation, allAttributes: [], parentProductSKU: nil)
    }
}

// Helper in unit tests
extension ProductVariationFormViewModel {
    convenience init(productVariation: EditableProductVariationModel,
                     productImageActionHandler: ProductImageActionHandler,
                     storesManager: StoresManager = ServiceLocator.stores) {
        self.init(productVariation: productVariation,
                  allAttributes: [],
                  parentProductSKU: nil,
                  productImageActionHandler: productImageActionHandler,
                  storesManager: storesManager)
    }
}
