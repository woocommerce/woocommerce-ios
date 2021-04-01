import Photos
import XCTest

@testable import WooCommerce
import Yosemite

/// Unit tests for unsaved changes (`hasUnsavedChanges`)
final class ProductVariationFormViewModel_ChangesTests: XCTestCase {
    private let defaultSiteID: Int64 = 134

    func test_product_variation_has_no_changes_from_edit_actions_of_the_same_data() {
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
        viewModel.updateShippingSettings(weight: productVariation.weight, dimensions: productVariation.dimensions, shippingClass: nil, shippingClassID: nil)

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }

    func test_product_variation_has_unsaved_changes_from_uploading_an_image() {
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
    }

    func test_product_variation_has_unsaved_changes_from_editing_images() {
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
    }

    func test_product_variation_has_unsaved_changes_from_editing_description() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updateDescription("Another way to describe the product?")

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_variation_has_unsaved_changes_from_editing_price_settings() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updatePriceSettings(regularPrice: "999999", salePrice: "888888", dateOnSaleStart: nil, dateOnSaleEnd: nil, taxStatus: .none, taxClass: nil)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_variation_has_unsaved_changes_from_editing_inventory_settings() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updateInventorySettings(sku: "", manageStock: false, soldIndividually: nil, stockQuantity: 888888, backordersSetting: nil, stockStatus: nil)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_variation_has_unsaved_changes_from_editing_shipping_settings() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updateShippingSettings(weight: "88888", dimensions: productVariation.dimensions, shippingClass: nil, shippingClassID: nil)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_variation_has_unsaved_changes_from_editing_attributes() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let model = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductVariationFormViewModel(productVariation: model, productImageActionHandler: productImageActionHandler)

        // Action
        let attributes = [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")]
        viewModel.updateVariationAttributes(attributes)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_action_buttons_for_existing_product_and_pending_changes() {
        // Given
        let productVariation = MockProductVariation().productVariation()
        let variationModel = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: variationModel)
        let viewModel = ProductVariationFormViewModel(productVariation: variationModel, formType: .edit, productImageActionHandler: productImageActionHandler)

        let attributes = [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")]
        viewModel.updateVariationAttributes(attributes)

        // When
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.save, .more])
    }

    func test_action_buttons_for_existing_product_and_no_pending_changes() {
        // Given
        let productVariation = MockProductVariation().productVariation()
        let variationModel = EditableProductVariationModel(productVariation: productVariation)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: variationModel)
        let viewModel = ProductVariationFormViewModel(productVariation: variationModel, formType: .edit, productImageActionHandler: productImageActionHandler)

        // When
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.more])
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
                     formType: ProductFormType = .edit,
                     productImageActionHandler: ProductImageActionHandler,
                     storesManager: StoresManager = ServiceLocator.stores) {
        self.init(productVariation: productVariation,
                  allAttributes: [],
                  parentProductSKU: nil,
                  formType: formType,
                  productImageActionHandler: productImageActionHandler,
                  storesManager: storesManager)
    }
}
