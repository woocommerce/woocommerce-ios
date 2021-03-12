import Photos
import XCTest
import Fakes

@testable import WooCommerce
import Yosemite

/// Unit tests for unsaved changes (`hasUnsavedChanges`)
final class ProductFormViewModel_ChangesTests: XCTestCase {
    private let defaultSiteID: Int64 = 134

    func testProductHasNoChangesFromEditActionsOfTheSameData() {
        // Arrange
        let product = Fakes.ProductFactory.productWithEditableDataFilled()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
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
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updateName("this new product name")

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingPassword() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let settings = ProductSettings(from: product, password: "secret secret")
        viewModel.updateProductSettings(settings)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromUploadingAnImage() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)
        let expectation = self.expectation(description: "Wait for image upload")
        productImageActionHandler.addUpdateObserver(self) { statuses in
            if statuses.productImageStatuses.isNotEmpty {
                expectation.fulfill()
            }
        }

        // Action
        productImageActionHandler.uploadMediaAssetToSiteMediaLibrary(asset: PHAsset())

        // Assert
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingImages() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

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

    func testProductHasUnsavedChangesFromEditingProductDescription() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updateDescription("Another way to describe the product?")

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingProductCategories() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let categoryID = Int64(1234)
        let parentID = Int64(1)
        let name = "Test category"
        let slug = "test-category"
        let newCategories = [ProductCategory(categoryID: categoryID, siteID: product.siteID, parentID: parentID, name: name, slug: slug)]
        viewModel.updateProductCategories(newCategories)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingProductTags() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let tagID = Int64(1234)
        let name = "Test tag"
        let slug = "test-tag"
        let newTags = [ProductTag(siteID: defaultSiteID, tagID: tagID, name: name, slug: slug)]
        viewModel.updateProductTags(newTags)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingProductShortDescription() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updateShortDescription("A short one")

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingPriceSettings() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updatePriceSettings(regularPrice: "999999", salePrice: "888888", dateOnSaleStart: nil, dateOnSaleEnd: nil, taxStatus: .none, taxClass: nil)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingInventorySettings() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updateInventorySettings(sku: "", manageStock: false, soldIndividually: true, stockQuantity: 888888, backordersSetting: nil, stockStatus: nil)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testProductHasUnsavedChangesFromEditingShippingSettings() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        viewModel.updateShippingSettings(weight: "88888",
                                         dimensions: product.dimensions,
                                         shippingClass: product.shippingClass,
                                         shippingClassID: product.shippingClassID)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_has_unsaved_changes_from_editing_downloadableFiles() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let downloads = Fakes.ProductFactory.productWithDownloadableFiles().downloads
        viewModel.updateDownloadableFiles(downloadableFiles: downloads, downloadLimit: 1, downloadExpiry: 1)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_has_unsaved_changes_from_editing_downloadLimit() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let downloads = Fakes.ProductFactory.productWithDownloadableFiles().downloads
        viewModel.updateDownloadableFiles(downloadableFiles: downloads, downloadLimit: 5, downloadExpiry: 1)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_product_has_unsaved_changes_from_editing_downloadExpiry() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let downloads = Fakes.ProductFactory.productWithDownloadableFiles().downloads
        viewModel.updateDownloadableFiles(downloadableFiles: downloads, downloadLimit: 1, downloadExpiry: 5)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }
}
