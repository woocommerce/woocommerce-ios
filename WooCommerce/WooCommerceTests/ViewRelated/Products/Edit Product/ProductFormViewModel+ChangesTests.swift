import Photos
import XCTest

@testable import WooCommerce
import Yosemite

/// Unit tests for unsaved changes (`hasUnsavedChanges`, `hasProductChanged`, `hasPasswordChanged`)
final class ProductFormViewModelTests_Changes: XCTestCase {
    private let defaultSiteID: Int64 = 134

    func testProductHasNoChangesFromEditActionsOfTheSameData() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)
        let taxClass = TaxClass(siteID: product.siteID, name: "standard", slug: product.taxClass ?? "standard")

        // Action
        viewModel.updateName(product.name)
        viewModel.updateDescription(product.fullDescription ?? "")
        viewModel.updateBriefDescription(product.briefDescription ?? "")
        viewModel.updateProductSettings(ProductSettings(from: product, password: nil))
        viewModel.updatePriceSettings(regularPrice: product.regularPrice, salePrice: product.salePrice, dateOnSaleStart: product.dateOnSaleStart, dateOnSaleEnd: product.dateOnSaleEnd, taxStatus: product.productTaxStatus, taxClass: taxClass)
        viewModel.updateInventorySettings(sku: product.sku, manageStock: product.manageStock, soldIndividually: product.soldIndividually, stockQuantity: product.stockQuantity, backordersSetting: product.backordersSetting, stockStatus: product.productStockStatus)
        viewModel.updateShippingSettings(weight: product.weight, dimensions: product.dimensions, shippingClass: product.productShippingClass)

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
        XCTAssertFalse(viewModel.hasProductChanged())
        XCTAssertFalse(viewModel.hasPasswordChanged())
    }

    func testProductHasUnsavedChangesFromEditingProductName() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        viewModel.updateName("this new product name")

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertTrue(viewModel.hasProductChanged())
        XCTAssertFalse(viewModel.hasPasswordChanged())
    }

    func testProductHasUnsavedChangesFromEditingPassword() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        let settings = ProductSettings(from: product, password: "secret secret")
        viewModel.updateProductSettings(settings)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertFalse(viewModel.hasProductChanged())
        XCTAssertTrue(viewModel.hasPasswordChanged())
    }

    func testProductHasUnsavedChangesFromUploadingAnImage() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)
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
        XCTAssertFalse(viewModel.hasProductChanged())
        XCTAssertFalse(viewModel.hasPasswordChanged())
    }

    func testProductHasUnsavedChangesFromEditingImages() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

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

    func testProductHasUnsavedChangesFromEditingProductDescription() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        viewModel.updateDescription("Another way to describe the product?")

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertTrue(viewModel.hasProductChanged())
        XCTAssertFalse(viewModel.hasPasswordChanged())
    }

    func testProductHasUnsavedChangesFromEditingProductBriefDescription() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        viewModel.updateBriefDescription("A short one")

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertTrue(viewModel.hasProductChanged())
        XCTAssertFalse(viewModel.hasPasswordChanged())
    }

    func testProductHasUnsavedChangesFromEditingPriceSettings() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        viewModel.updatePriceSettings(regularPrice: "999999", salePrice: "888888", dateOnSaleStart: nil, dateOnSaleEnd: nil, taxStatus: .none, taxClass: nil)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertTrue(viewModel.hasProductChanged())
        XCTAssertFalse(viewModel.hasPasswordChanged())
    }

    func testProductHasUnsavedChangesFromEditingInventorySettings() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        viewModel.updateInventorySettings(sku: "", manageStock: false, soldIndividually: true, stockQuantity: 888888, backordersSetting: nil, stockStatus: nil)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertTrue(viewModel.hasProductChanged())
        XCTAssertFalse(viewModel.hasPasswordChanged())
    }

    func testProductHasUnsavedChangesFromEditingShippingSettings() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        viewModel.updateShippingSettings(weight: "88888", dimensions: product.dimensions, shippingClass: product.productShippingClass)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
        XCTAssertTrue(viewModel.hasProductChanged())
        XCTAssertFalse(viewModel.hasPasswordChanged())
    }
}
