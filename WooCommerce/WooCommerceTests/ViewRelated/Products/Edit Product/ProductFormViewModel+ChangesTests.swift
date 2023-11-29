import Combine
import Photos
import XCTest
import Fakes

@testable import WooCommerce
import Yosemite

/// Unit tests for unsaved changes (`hasUnsavedChanges`)
final class ProductFormViewModel_ChangesTests: XCTestCase {
    private let defaultSiteID: Int64 = 134
    private var productImageStatusesSubscription: AnyCancellable?

    private var product: Product!
    private var model: EditableProductModel!
    private var mockProductImageUploader: MockProductImageUploader!
    private var productImageActionHandler: ProductImageActionHandler!
    private var viewModel: ProductFormViewModel!

    override func setUp() {
        super.setUp()
        let subscription = ProductSubscription.fake()
        product = Product.fake().copy(subscription: subscription)
        model = EditableProductModel(product: product)
        mockProductImageUploader = MockProductImageUploader()
        productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)

        viewModel = ProductFormViewModel(product: model,
                                         formType: .edit,
                                         productImageActionHandler: productImageActionHandler,
                                         productImagesUploader: mockProductImageUploader
        )
    }

    override func tearDown() {
        product = nil
        model = nil
        mockProductImageUploader = nil
        productImageActionHandler = nil
        viewModel = nil
        super.tearDown()
    }

    func testProductHasNoChangesFromEditActionsOfTheSameData() {
        // Arrange
        product = Fakes.ProductFactory.productWithEditableDataFilled()
        model = EditableProductModel(product: product)
        productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)

        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)
        let taxClass = TaxClass(siteID: product.siteID, name: "standard", slug: product.taxClass ?? "standard")

        // Action
        viewModel.updateName(product.name)
        viewModel.updateDescription(product.fullDescription ?? "")
        viewModel.updateShortDescription(product.shortDescription ?? "")
        viewModel.updateProductSettings(ProductSettings(from: product, password: nil))
        viewModel.updatePriceSettings(regularPrice: product.regularPrice,
                                      subscriptionPeriod: product.subscription?.period,
                                      subscriptionPeriodInterval: product.subscription?.periodInterval,
                                      subscriptionSignupFee: product.subscription?.signUpFee,
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
                                         oneTimeShipping: product.subscription?.oneTimeShipping,
                                         shippingClass: product.shippingClass,
                                         shippingClassID: product.shippingClassID)
        viewModel.updateProductCategories(product.categories)
        viewModel.updateProductTags(product.tags)

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingProductName() {
        // Action
        viewModel.updateName("this new product name")

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingPassword() {
        // Action
        let settings = ProductSettings(from: product, password: "secret secret")
        viewModel.updateProductSettings(settings)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_hasUnsavedChanges_when_productImagesUploader_hasUnsavedChangesOnImages_then_returns_true() {
        // When
        mockProductImageUploader.whenHasUnsavedChangesOnImagesIsCalled(thenReturn: true)
        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_hasUnsavedChangesOnImages_when_productImagesUploader_hasUnsavedChangesOnImagesFromEditingImages_then_returns_true() {
        // Given
        let productImage = ProductImage(imageID: 6,
                                        dateCreated: Date(),
                                        dateModified: Date(),
                                        src: "",
                                        name: "woo",
                                        alt: nil)


        // When
        mockProductImageUploader.whenHasUnsavedChangesOnImagesIsCalled(thenReturn: true)
        let unsavedChanges = mockProductImageUploader.hasUnsavedChangesOnImages(
            key: .init(
                siteID: defaultSiteID,
                productOrVariationID: .product(id: product.productID),
                isLocalID: false),
            originalImages: [productImage])
        viewModel.updateImages([productImage])

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertTrue(unsavedChanges)
    }

    func testProductHasUnsavedChangesFromEditingProductDescription() {
        // When
        viewModel.updateDescription("Another way to describe the product?")

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingProductCategories() {
        // Given
        let categoryID = Int64(1234)
        let parentID = Int64(1)
        let name = "Test category"
        let slug = "test-category"
        let newCategories = [ProductCategory(categoryID: categoryID, siteID: product.siteID, parentID: parentID, name: name, slug: slug)]

        // When
        viewModel.updateProductCategories(newCategories)

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingProductTags() {
        // Given
        let tagID = Int64(1234)
        let name = "Test tag"
        let slug = "test-tag"
        let newTags = [ProductTag(siteID: defaultSiteID, tagID: tagID, name: name, slug: slug)]

        // When
        viewModel.updateProductTags(newTags)

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingProductShortDescription() {
        // When
        viewModel.updateShortDescription("A short one")

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingPriceSettings() {
        // When
        viewModel.updatePriceSettings(regularPrice: "999999",
                                      subscriptionPeriod: nil,
                                      subscriptionPeriodInterval: nil,
                                      subscriptionSignupFee: nil,
                                      salePrice: "888888",
                                      dateOnSaleStart: nil,
                                      dateOnSaleEnd: nil,
                                      taxStatus: .none,
                                      taxClass: nil)

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_has_unsaved_changes_from_editing_subscription_period_settings() {
        // When
        viewModel.updatePriceSettings(regularPrice: "",
                                      subscriptionPeriod: .month,
                                      subscriptionPeriodInterval: "1",
                                      subscriptionSignupFee: nil,
                                      salePrice: "",
                                      dateOnSaleStart: nil,
                                      dateOnSaleEnd: nil,
                                      taxStatus: .none,
                                      taxClass: nil)

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_has_unsaved_changes_from_editing_subscription_signup_fee() {
        // When
        viewModel.updatePriceSettings(regularPrice: "",
                                      subscriptionPeriod: nil,
                                      subscriptionPeriodInterval: nil,
                                      subscriptionSignupFee: "0.99",
                                      salePrice: "",
                                      dateOnSaleStart: nil,
                                      dateOnSaleEnd: nil,
                                      taxStatus: .none,
                                      taxClass: nil)

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingInventorySettings() {
        // When
        viewModel.updateInventorySettings(
            sku: "",
            manageStock: false,
            soldIndividually: true,
            stockQuantity: 888888,
            backordersSetting: nil,
            stockStatus: nil
        )

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingShippingSettings() {
        // When
        viewModel.updateShippingSettings(weight: "88888",
                                         dimensions: product.dimensions,
                                         oneTimeShipping: product.subscription?.oneTimeShipping,
                                         shippingClass: product.shippingClass,
                                         shippingClassID: product.shippingClassID)

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_has_unsaved_changes_from_editing_oneTimeShipping() {
        // When
        viewModel.updateShippingSettings(weight: product.weight,
                                         dimensions: product.dimensions,
                                         oneTimeShipping: true,
                                         shippingClass: product.shippingClass,
                                         shippingClassID: product.shippingClassID)

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_has_unsaved_changes_from_editing_downloadableFiles() {
        // Given
        let downloads = Fakes.ProductFactory.productWithDownloadableFiles().downloads

        // When
        viewModel.updateDownloadableFiles(downloadableFiles: downloads, downloadLimit: 1, downloadExpiry: 1)

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_has_unsaved_changes_from_editing_downloadLimit() {
        // Given
        let downloads = Fakes.ProductFactory.productWithDownloadableFiles().downloads

        // When
        viewModel.updateDownloadableFiles(downloadableFiles: downloads, downloadLimit: 5, downloadExpiry: 1)

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_has_unsaved_changes_from_editing_downloadExpiry() {
        // Given
        let downloads = Fakes.ProductFactory.productWithDownloadableFiles().downloads

        // When
        viewModel.updateDownloadableFiles(downloadableFiles: downloads, downloadLimit: 1, downloadExpiry: 5)

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    // MARK: Expire after

    func test_updatePriceSettings_sets_length_to_zero_when_subscription_period_changes() throws {
        // Given
        let product = Product.fake().copy(subscription: .fake().copy(period: .week,
                                                                     periodInterval: "1",
                                                                     trialLength: "4",
                                                                     trialPeriod: .month))
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                    formType: .edit,
                                    productImageActionHandler: productImageActionHandler)

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
        let product = Product.fake().copy(subscription: .fake().copy(period: .day,
                                                                     periodInterval: "1",
                                                                     trialLength: "4",
                                                                     trialPeriod: .month))
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                    formType: .edit,
                                    productImageActionHandler: productImageActionHandler)

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
        let product = Product.fake().copy(subscription: .fake().copy(length: "5",
                                                                     period: .day,
                                                                     periodInterval: "1",
                                                                     trialLength: "4",
                                                                     trialPeriod: .month))
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                    formType: .edit,
                                    productImageActionHandler: productImageActionHandler)

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

    // MARK: Free trial

    func test_updateSubscriptionFreeTrialSettings_changes_oneTimeShipping_to_false_when_there_is_free_trial() throws {
        // Given
        let product = Product.fake().copy(subscription: .fake().copy(period: .week,
                                                                     periodInterval: "1",
                                                                     trialLength: "0",
                                                                     trialPeriod: .month,
                                                                     oneTimeShipping: true))
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                    formType: .edit,
                                    productImageActionHandler: productImageActionHandler)

        // When
        viewModel.updateSubscriptionFreeTrialSettings(trialLength: "1", trialPeriod: .month)

        // Then
        let subscription = try XCTUnwrap(viewModel.productModel.subscription)
        XCTAssertFalse(subscription.oneTimeShipping)
    }

    func test_updateSubscriptionFreeTrialSettings_does_not_change_oneTimeShipping_when_there_is_no_free_trial() throws {
        // Given
        let product = Product.fake().copy(subscription: .fake().copy(period: .week,
                                                                     periodInterval: "1",
                                                                     trialLength: "0",
                                                                     trialPeriod: .month,
                                                                     oneTimeShipping: true))
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                    formType: .edit,
                                    productImageActionHandler: productImageActionHandler)

        // When
        viewModel.updateSubscriptionFreeTrialSettings(trialLength: "0", trialPeriod: .year)

        // Then
        let subscription = try XCTUnwrap(viewModel.productModel.subscription)
        XCTAssertTrue(subscription.oneTimeShipping)
    }
}
