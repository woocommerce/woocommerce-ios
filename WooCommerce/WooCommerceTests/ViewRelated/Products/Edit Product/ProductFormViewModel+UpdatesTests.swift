import Photos
import XCTest
import Fakes

@testable import WooCommerce
import Yosemite

/// Unit tests for update functions in `ProductFormViewModel`.
final class ProductFormViewModel_UpdatesTests: XCTestCase {
    func testUpdatingName() {
        // Arrange
        let product = Product.fake().copy(name: "Test")
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let newName = "<p> cool product </p>"
        viewModel.updateName(newName)

        // Assert
        XCTAssertEqual(viewModel.productModel.name, newName)
    }

    func testUpdatingDescription() {
        // Arrange
        let product = Product.fake().copy(fullDescription: "Test")
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let newDescription = "<p> cool product </p>"
        viewModel.updateDescription(newDescription)

        // Assert
        XCTAssertEqual(viewModel.productModel.description, newDescription)
    }

    func testUpdatingShippingSettings() {
        // Arrange
        let subscription = ProductSubscription.fake()
        let product = Product.fake().copy(subscription: subscription)
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let newWeight = "9999.88"
        let newDimensions = ProductDimensions(length: "122", width: "333", height: "")
        let newShippingClass = ProductShippingClass(count: 2020,
                                                    descriptionHTML: "Arriving in 2 days!",
                                                    name: "2 Days",
                                                    shippingClassID: 2022,
                                                    siteID: product.siteID,
                                                    slug: "2-days")
        viewModel.updateShippingSettings(weight: newWeight,
                                         dimensions: newDimensions,
                                         oneTimeShipping: true,
                                         shippingClass: newShippingClass.slug,
                                         shippingClassID: newShippingClass.shippingClassID)

        // Assert
        XCTAssertEqual(viewModel.productModel.description, product.fullDescription)
        XCTAssertEqual(viewModel.productModel.name, product.name)
        XCTAssertEqual(viewModel.productModel.weight, newWeight)
        XCTAssertEqual(viewModel.productModel.dimensions, newDimensions)
        XCTAssertEqual(viewModel.productModel.subscription?.oneTimeShipping, true)
        XCTAssertEqual(viewModel.productModel.shippingClass, newShippingClass.slug)
        XCTAssertEqual(viewModel.productModel.shippingClassID, newShippingClass.shippingClassID)
        XCTAssertEqual(viewModel.productModel.shippingClass, newShippingClass.slug)
    }

    func testUpdatingPriceSettings() {
        // Arrange
        let subscription = ProductSubscription.fake()
        let product = Product.fake().copy(subscription: subscription)
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let newRegularPrice = "32.45"
        let newSalePrice = "20.00"
        let newDateOnSaleStart = Date()
        let newDateOnSaleEnd = newDateOnSaleStart.addingTimeInterval(86400)
        let newTaxStatus = ProductTaxStatus.taxable
        let newTaxClass = TaxClass(siteID: product.siteID, name: "Reduced rate", slug: "reduced-rate")
        let newSubscriptionPeriod = SubscriptionPeriod.month
        let newSubscriptionInterval = "2"
        let newSubscriptionSignupFee = "0.99"
        viewModel.updatePriceSettings(regularPrice: newRegularPrice,
                                      subscriptionPeriod: newSubscriptionPeriod,
                                      subscriptionPeriodInterval: newSubscriptionInterval,
                                      subscriptionSignupFee: newSubscriptionSignupFee,
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
        XCTAssertEqual(viewModel.productModel.subscription?.period, newSubscriptionPeriod)
        XCTAssertEqual(viewModel.productModel.subscription?.periodInterval, newSubscriptionInterval)
        XCTAssertEqual(viewModel.productModel.subscription?.signUpFee, newSubscriptionSignupFee)
    }

    func testUpdatingInventorySettings() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let newSKU = "94115"
        let newManageStock = !product.manageStock
        let newSoldIndividually = !product.soldIndividually
        let newStockQuantity: Decimal = 17
        let newBackordersSetting = ProductBackordersSetting.allowedAndNotifyCustomer
        let newStockStatus = ProductStockStatus.onBackOrder
        viewModel.updateInventorySettings(sku: newSKU,
                                          manageStock: newManageStock,
                                          soldIndividually: newSoldIndividually,
                                          stockQuantity: newStockQuantity,
                                          backordersSetting: newBackordersSetting,
                                          stockStatus: newStockStatus)

        // Assert
        XCTAssertEqual(viewModel.productModel.sku, newSKU)
        XCTAssertEqual(viewModel.productModel.manageStock, newManageStock)
        XCTAssertEqual(viewModel.productModel.product.soldIndividually, newSoldIndividually)
        XCTAssertEqual(viewModel.productModel.stockQuantity, newStockQuantity)
        XCTAssertEqual(viewModel.productModel.backordersSetting, newBackordersSetting)
        XCTAssertEqual(viewModel.productModel.stockStatus, newStockStatus)
    }

    func testUpdatingImages() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let newImage = ProductImage(imageID: 17,
                                    dateCreated: DateFormatter.dateFromString(with: "2018-01-26T21:49:45"),
                                    dateModified: DateFormatter.dateFromString(with: "2018-01-26T21:50:11"),
                                    src: "https://somewebsite.com/shirt.jpg",
                                    name: "Tshirt",
                                    alt: "")
        let newImages = [newImage]
        viewModel.updateImages(newImages)

        // Assert
        XCTAssertEqual(viewModel.productModel.images, newImages)
    }

    func testUpdatingProductCategories() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
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
        XCTAssertEqual(viewModel.productModel.product.categories, newCategories)
    }

    func testUpdatingProductTags() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let tagID = Int64(1234)
        let name = "Test tag"
        let slug = "test-tag"
        let newTags = [ProductTag(siteID: 0, tagID: tagID, name: name, slug: slug)]
        viewModel.updateProductTags(newTags)

        // Assert
        XCTAssertEqual(viewModel.productModel.product.tags, newTags)
    }

    func testUpdatingShortDescription() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let newShortDescription = "<p> deal of the day! </p>"
        viewModel.updateShortDescription(newShortDescription)

        // Assert
        XCTAssertEqual(viewModel.productModel.shortDescription, newShortDescription)
    }

    func testUpdatingProductSettings() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let newStatus = "pending"
        let featured = true
        let password = ""
        let catalogVisibility = "search"
        let virtual = true
        let downloadable = true
        let reviewsAllowed = true
        let slug = "this-is-a-test"
        let purchaseNote = "This is a purchase note"
        let menuOrder = 0
        let productSettings = ProductSettings(productType: .simple,
                                              status: .pending,
                                              featured: featured,
                                              password: password,
                                              catalogVisibility: .search,
                                              virtual: virtual,
                                              reviewsAllowed: reviewsAllowed,
                                              slug: slug,
                                              purchaseNote: purchaseNote,
                                              menuOrder: menuOrder,
                                              downloadable: downloadable)
        viewModel.updateProductSettings(productSettings)

        // Assert
        XCTAssertEqual(viewModel.productModel.product.statusKey, newStatus)
        XCTAssertEqual(viewModel.productModel.product.featured, featured)
        XCTAssertEqual(viewModel.productModel.product.catalogVisibilityKey, catalogVisibility)
        XCTAssertEqual(viewModel.productModel.product.reviewsAllowed, reviewsAllowed)
        XCTAssertEqual(viewModel.productModel.product.slug, slug)
        XCTAssertEqual(viewModel.productModel.product.purchaseNote, purchaseNote)
        XCTAssertEqual(viewModel.productModel.product.menuOrder, menuOrder)
    }

    func testUpdatingSKU() {
        // Arrange
        let product = Product.fake().copy(sku: "")
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let sku = "woooo"
        viewModel.updateSKU(sku)

        // Assert
        XCTAssertEqual(viewModel.productModel.sku, sku)
    }

    func testUpdatingExternalLink() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let externalURL = "woo.com"
        let buttonText = "Try!"
        viewModel.updateExternalLink(externalURL: externalURL, buttonText: buttonText)

        // Assert
        XCTAssertEqual(viewModel.productModel.product.externalURL, externalURL)
        XCTAssertEqual(viewModel.productModel.product.buttonText, buttonText)
    }

    func testUpdatingGroupedProductIDs() {
        // Arrange
        let product = Product.fake()
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let groupedProductIDs: [Int64] = [630, 22]
        viewModel.updateGroupedProductIDs(groupedProductIDs)

        // Assert
        XCTAssertEqual(viewModel.productModel.product.groupedProducts, groupedProductIDs)
    }

    func test_updating_downloadableFiles_info() {
        // Arrange
        let product = Product.fake().copy(downloadable: true)
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: productImageActionHandler)

        // Action
        let newDownloadableFiles = Fakes.ProductFactory.productWithDownloadableFiles().downloads
        let newDownloadLimit: Int64 = 5
        let newDownloadExpiry: Int64 = 5
        viewModel.updateDownloadableFiles(downloadableFiles: newDownloadableFiles,
                                          downloadLimit: newDownloadLimit,
                                          downloadExpiry: newDownloadExpiry)

        // Assert
        XCTAssertEqual(viewModel.productModel.downloadableFiles.count, newDownloadableFiles.count)
        XCTAssertEqual(viewModel.productModel.downloadLimit, newDownloadLimit)
        XCTAssertEqual(viewModel.productModel.product.downloadExpiry, newDownloadExpiry)
    }
}

extension ProductImageActionHandler {
    convenience init(siteID: Int64, product: ProductFormDataModel) {
        self.init(siteID: siteID, productID: .product(id: product.productID), imageStatuses: product.imageStatuses)
    }
}
