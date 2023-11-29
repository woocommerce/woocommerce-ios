import Combine
import Photos
import XCTest

@testable import WooCommerce
import Yosemite

/// Unit tests for unsaved changes (`hasUnsavedChanges`)
final class ProductVariationFormViewModel_ChangesTests: XCTestCase {
    private let defaultSiteID: Int64 = 134
    private var productImageStatusesSubscription: AnyCancellable?

    private var productVariation: ProductVariation!
    private var model: EditableProductVariationModel!
    private var productImageActionHandler: ProductImageActionHandler!
    private var mockProductImageUploader: MockProductImageUploader!
    private var viewModel: ProductVariationFormViewModel!

    override func setUp() {
        super.setUp()
        productVariation = MockProductVariation().productVariation()
        model = EditableProductVariationModel(productVariation: productVariation)
        productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        mockProductImageUploader = MockProductImageUploader()

        viewModel = ProductVariationFormViewModel(
            productVariation: model,
            productImageActionHandler: productImageActionHandler,
            productImagesUploader: mockProductImageUploader
        )
    }

    override func tearDown() {
        productVariation = nil
        model = nil
        productImageActionHandler = nil
        mockProductImageUploader = nil
        viewModel = nil
        super.tearDown()
    }

    func test_product_variation_has_no_changes_from_edit_actions_of_the_same_data() {
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
        viewModel.updateShippingSettings(weight: productVariation.weight,
                                         dimensions: productVariation.dimensions,
                                         oneTimeShipping: nil,
                                         shippingClass: nil,
                                         shippingClassID: nil)

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }

    func test_product_variation_has_unsaved_changes_from_uploading_an_image() {
       // Action
        mockProductImageUploader.whenHasUnsavedChangesOnImagesIsCalled(thenReturn: true)
        waitForExpectation { expectation in
            self.productImageStatusesSubscription = productImageActionHandler.addUpdateObserver(self) { statuses in
                if statuses.productImageStatuses.isNotEmpty {
                    expectation.fulfill()
                }
            }
            productImageActionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: PHAsset()))
        }

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_variation_has_unsaved_changes_from_editing_images() {
        // Given
        let productImage = ProductImage(imageID: 6,
                                        dateCreated: Date(),
                                        dateModified: Date(),
                                        src: "",
                                        name: "woo",
                                        alt: nil)
        // When
        mockProductImageUploader.whenHasUnsavedChangesOnImagesIsCalled(thenReturn: true)
        viewModel.updateImages([productImage])

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_variation_has_unsaved_changes_from_editing_description() {
        // Action
        viewModel.updateDescription("Another way to describe the product?")

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_variation_has_unsaved_changes_from_editing_price_settings() {
        // Action
        viewModel.updatePriceSettings(regularPrice: "999999",
                                      subscriptionPeriod: nil,
                                      subscriptionPeriodInterval: nil,
                                      subscriptionSignupFee: nil,
                                      salePrice: "888888",
                                      dateOnSaleStart: nil,
                                      dateOnSaleEnd: nil,
                                      taxStatus: .none,
                                      taxClass: nil)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_variation_has_unsaved_changes_from_editing_subscription_period_settings() {
        // Action
        viewModel.updatePriceSettings(regularPrice: "",
                                      subscriptionPeriod: .week,
                                      subscriptionPeriodInterval: "3",
                                      subscriptionSignupFee: nil,
                                      salePrice: "",
                                      dateOnSaleStart: nil,
                                      dateOnSaleEnd: nil,
                                      taxStatus: .none,
                                      taxClass: nil)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_variation_has_unsaved_changes_from_editing_subscription_signup_fee() {
        // Action
        viewModel.updatePriceSettings(regularPrice: "",
                                      subscriptionPeriod: nil,
                                      subscriptionPeriodInterval: nil,
                                      subscriptionSignupFee: "0.99",
                                      salePrice: "",
                                      dateOnSaleStart: nil,
                                      dateOnSaleEnd: nil,
                                      taxStatus: .none,
                                      taxClass: nil)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_variation_has_unsaved_changes_from_editing_inventory_settings() {
        // Action
        viewModel.updateInventorySettings(sku: "", manageStock: false, soldIndividually: nil, stockQuantity: 888888, backordersSetting: nil, stockStatus: nil)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_variation_has_unsaved_changes_from_editing_shipping_settings() {
        // Action
        viewModel.updateShippingSettings(weight: "88888",
                                         dimensions: productVariation.dimensions,
                                         oneTimeShipping: nil,
                                         shippingClass: nil,
                                         shippingClassID: nil)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_variation_has_unsaved_changes_from_editing_attributes() {
        // Action
        let attributes = [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")]
        viewModel.updateVariationAttributes(attributes)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_action_buttons_for_existing_product_and_pending_changes() {
        // Given
        let attributes = [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")]

        // When
        viewModel.updateVariationAttributes(attributes)
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.save, .more])
    }

    func test_action_buttons_for_existing_product_and_no_pending_changes() {
        // When
        let actionButtons = viewModel.actionButtons

        // Then
        XCTAssertEqual(actionButtons, [.more])
    }

    // MARK: Expire after

    func test_updatePriceSettings_sets_length_to_zero_when_subscription_period_changes() throws {
        // Given
        let productVariation = ProductVariation.fake().copy(subscription: .fake().copy(period: .week,
                                                                                       periodInterval: "1",
                                                                                       trialLength: "4",
                                                                                       trialPeriod: .month))
        let model = EditableProductVariationModel(productVariation: productVariation)

        let viewModel = ProductVariationFormViewModel(productVariation: model,
                                                      productImageActionHandler: productImageActionHandler,
                                                      productImagesUploader: mockProductImageUploader)

        // When
        viewModel.updatePriceSettings(regularPrice: "999999",
                                      subscriptionPeriod: .day,
                                      subscriptionPeriodInterval: "1",
                                      subscriptionSignupFee: nil,
                                      salePrice: "888888",
                                      dateOnSaleStart: nil,
                                      dateOnSaleEnd: nil,
                                      taxStatus: .none,
                                      taxClass: nil)

        // Then
        let subscription = try XCTUnwrap(viewModel.productModel.subscription)
        XCTAssertEqual(subscription.length, "0")
    }

    func test_updatePriceSettings_sets_length_to_zero_when_subscription_periodInterval_changes() throws {
        // Given
        let productVariation = ProductVariation.fake().copy(subscription: .fake().copy(period: .day,
                                                                                       periodInterval: "1",
                                                                                       trialLength: "4",
                                                                                       trialPeriod: .month))
        let model = EditableProductVariationModel(productVariation: productVariation)

        let viewModel = ProductVariationFormViewModel(productVariation: model,
                                                      productImageActionHandler: productImageActionHandler,
                                                      productImagesUploader: mockProductImageUploader)

        // When
        viewModel.updatePriceSettings(regularPrice: "999999",
                                      subscriptionPeriod: .day,
                                      subscriptionPeriodInterval: "2",
                                      subscriptionSignupFee: nil,
                                      salePrice: "888888",
                                      dateOnSaleStart: nil,
                                      dateOnSaleEnd: nil,
                                      taxStatus: .none,
                                      taxClass: nil)

        // Then
        let subscription = try XCTUnwrap(viewModel.productModel.subscription)
        XCTAssertEqual(subscription.length, "0")
    }

    func test_updatePriceSettings_does_not_change_length_when_subscription_period_and_periodInterval_changes() throws {
        // Given
        let productVariation = ProductVariation.fake().copy(subscription: .fake().copy(length: "5",
                                                                                       period: .day,
                                                                                       periodInterval: "1",
                                                                                       trialLength: "4",
                                                                                       trialPeriod: .month))
        let model = EditableProductVariationModel(productVariation: productVariation)
        let viewModel = ProductVariationFormViewModel(productVariation: model,
                                                      productImageActionHandler: productImageActionHandler,
                                                      productImagesUploader: mockProductImageUploader)

        // When
        viewModel.updatePriceSettings(regularPrice: "999999",
                                      subscriptionPeriod: .day,
                                      subscriptionPeriodInterval: "1",
                                      subscriptionSignupFee: nil,
                                      salePrice: "888888",
                                      dateOnSaleStart: nil,
                                      dateOnSaleEnd: nil,
                                      taxStatus: .none,
                                      taxClass: nil)

        // Then
        let subscription = try XCTUnwrap(viewModel.productModel.subscription)
        XCTAssertEqual(subscription.length, "5")
    }
}

// Helper in unit tests
extension EditableProductVariationModel {
    convenience init(productVariation: ProductVariation) {
        self.init(productVariation: productVariation,
                  parentProductType: .variable,
                  allAttributes: [],
                  parentProductSKU: nil,
                  parentProductDisablesQuantityRules: nil)
    }
}

// Helper in unit tests
extension ProductVariationFormViewModel {
    convenience init(productVariation: EditableProductVariationModel,
                     formType: ProductFormType = .edit,
                     productImageActionHandler: ProductImageActionHandlerProtocol,
                     storesManager: StoresManager = ServiceLocator.stores,
                     productImagesUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader) {
        self.init(productVariation: productVariation,
                  allAttributes: [],
                  parentProductSKU: nil,
                  parentProductDisablesQuantityRules: nil,
                  formType: formType,
                  productImageActionHandler: productImageActionHandler,
                  storesManager: storesManager,
                  productImagesUploader: productImagesUploader)
    }
}
