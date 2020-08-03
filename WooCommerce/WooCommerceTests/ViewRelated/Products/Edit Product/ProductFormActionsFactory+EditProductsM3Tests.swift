import XCTest

@testable import WooCommerce
@testable import Yosemite

/// The same tests as `ProductFormActionsFactory_EditProductsM2Tests`, but with Edit Products M2 and M3 feature flag on.
/// When we fully launch Edit Products M2 and M3, we can replace `ProductFormActionsFactoryTests` with the test cases here.
///
final class ProductFormActionsFactory_EditProductsM3Tests: XCTestCase {
    func testViewModelForPhysicalSimpleProductWithoutImages() {
        // Arrange
        let product = Fixtures.physicalSimpleProductWithoutImages

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings,
                                                                       .reviews,
                                                                       .shippingSettings,
                                                                       .inventorySettings,
                                                                       .categories,
                                                                       .tags,
                                                                       .briefDescription]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForPhysicalSimpleProductWithImages() {
        // Arrange
        let product = Fixtures.physicalSimpleProductWithImages

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings,
                                                                       .reviews,
                                                                       .shippingSettings,
                                                                       .inventorySettings,
                                                                       .categories,
                                                                       .tags,
                                                                       .briefDescription]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForDownloadableSimpleProduct() {
        // Arrange
        let product = Fixtures.downloadableSimpleProduct

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings, .reviews, .inventorySettings, .categories, .tags, .briefDescription]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForVirtualSimpleProduct() {
        // Arrange
        let product = Fixtures.virtualSimpleProduct

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings, .reviews, .inventorySettings, .categories, .tags, .briefDescription]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForAffiliateProduct() {
        // Arrange
        let product = Fixtures.affiliateProduct

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings, .reviews, .externalURL]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editSKU, .editCategories, .editTags, .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForGroupedProduct() {
        // Arrange
        let product = Fixtures.groupedProduct

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.groupedProducts, .reviews]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editSKU, .editCategories, .editTags, .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForVariableProductWithoutVariations() {
        // Arrange
        let product = Fixtures.variableProductWithoutVariations

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.variations, .reviews]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForVariableProductWithVariations() {
        // Arrange
        let product = Fixtures.variableProductWithVariations

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.variations, .reviews]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }
}

private extension ProductFormActionsFactory_EditProductsM3Tests {
    enum Fixtures {
        static let category = ProductCategory(categoryID: 1, siteID: 2, parentID: 6, name: "", slug: "")
        static let image = ProductImage(imageID: 19,
                                        dateCreated: Date(),
                                        dateModified: Date(),
                                        src: "https://photo.jpg",
                                        name: "Tshirt",
                                        alt: "")
        static let tag = ProductTag(siteID: 123, tagID: 1, name: "", slug: "")
        // downloadable: false, virtual: false, with inventory/shipping/categories/tags/brief description
        static let physicalSimpleProductWithoutImages = MockProduct().product(downloadable: false, briefDescription: "desc", productType: .simple,
                                                                              manageStock: true, sku: "uks", stockQuantity: nil,
                                                                              dimensions: ProductDimensions(length: "", width: "", height: ""), weight: "2",
                                                                              virtual: false,
                                                                              categories: [category],
                                                                              tags: [tag],
                                                                              images: [])
        // downloadable: false, virtual: true, with inventory/shipping/categories/tags/brief description
        static let physicalSimpleProductWithImages = MockProduct().product(downloadable: false, briefDescription: "desc", productType: .simple,
                                                                              manageStock: true, sku: "uks", stockQuantity: nil,
                                                                              dimensions: ProductDimensions(length: "", width: "", height: ""), weight: "2",
                                                                              virtual: false,
                                                                              categories: [category],
                                                                              tags: [tag],
                                                                              images: [image])
        // downloadable: false, virtual: true, with inventory/shipping/categories/tags/brief description
        static let virtualSimpleProduct = MockProduct().product(downloadable: false, briefDescription: "desc", productType: .simple,
                                                                manageStock: true, sku: "uks", stockQuantity: nil,
                                                                dimensions: ProductDimensions(length: "", width: "", height: ""), weight: "2",
                                                                virtual: true,
                                                                categories: [category],
                                                                tags: [tag])
        // downloadable: true, virtual: true, missing inventory/shipping/categories/brief description
        static let downloadableSimpleProduct = MockProduct().product(downloadable: true, briefDescription: "desc", productType: .simple,
                                                                     manageStock: true, sku: "uks", stockQuantity: nil,
                                                                     dimensions: ProductDimensions(length: "", width: "", height: ""), weight: "3",
                                                                     virtual: true,
                                                                     categories: [category],
                                                                     tags: [tag])
        // Affiliate product, missing external URL/sku/inventory/brief description/categories/tags
        static let affiliateProduct = MockProduct().product(briefDescription: "",
                                                            externalURL: "",
                                                            productType: .affiliate,
                                                            sku: "",
                                                            categories: [],
                                                            tags: [])
        // Grouped product, missing grouped products/sku/brief description/categories/tags
        static let groupedProduct = MockProduct().product(briefDescription: "",
                                                          productType: .grouped,
                                                          sku: "")
        // Variable product, missing variations/brief description/categories/tags
        static let variableProductWithoutVariations = MockProduct().product(briefDescription: "",
                                                           productType: .variable,
                                                           sku: "").copy(variations: [])
        // Variable product with one variation, missing brief description/categories/tags
        static let variableProductWithVariations = MockProduct().product(briefDescription: "",
                                                           productType: .variable,
                                                           sku: "").copy(variations: [123])
    }
}
