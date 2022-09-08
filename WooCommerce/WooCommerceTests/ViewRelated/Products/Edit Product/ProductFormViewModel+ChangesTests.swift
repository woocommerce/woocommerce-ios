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
        product = Product.fake()
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
        viewModel.updatePriceSettings(regularPrice: "999999", salePrice: "888888", dateOnSaleStart: nil, dateOnSaleEnd: nil, taxStatus: .none, taxClass: nil)

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
}
