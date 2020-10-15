import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductFormActionsFactoryTests: XCTestCase {
    func testViewModelForPhysicalSimpleProductWithoutImages() {
        // Arrange
        let product = Fixtures.physicalSimpleProductWithoutImages
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true),
                                                                       .reviews,
                                                                       .shippingSettings(editable: true),
                                                                       .inventorySettings(editable: true),
                                                                       .categories(editable: true),
                                                                       .tags(editable: true),
                                                                       .briefDescription(editable: true),
                                                                       .productType(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForPhysicalSimpleProductWithImages() {
        // Arrange
        let product = Fixtures.physicalSimpleProductWithImages
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true),
                                                                       .reviews,
                                                                       .shippingSettings(editable: true),
                                                                       .inventorySettings(editable: true),
                                                                       .categories(editable: true),
                                                                       .tags(editable: true),
                                                                       .briefDescription(editable: true),
                                                                       .productType(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_viewModel_for_physical_simple_product_with_reviews_disabled() {
        // Arrange
        let product = Fixtures.physicalSimpleProductWithReviewsDisabled
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true),
                                                                       .shippingSettings(editable: true),
                                                                       .inventorySettings(editable: true),
                                                                       .categories(editable: true),
                                                                       .tags(editable: true),
                                                                       .briefDescription(editable: true),
                                                                       .productType(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForDownloadableSimpleProduct() {
        // Arrange
        let product = Fixtures.downloadableSimpleProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease5Enabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true),
                                                                       .reviews,
                                                                       .inventorySettings(editable: true),
                                                                       .categories(editable: true),
                                                                       .tags(editable: true),
                                                                       .downloadableFiles,
                                                                       .briefDescription(editable: true),
                                                                       .productType(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForVirtualSimpleProduct() {
        // Arrange
        let product = Fixtures.virtualSimpleProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true),
                                                                       .reviews,
                                                                       .inventorySettings(editable: true),
                                                                       .categories(editable: true),
                                                                       .tags(editable: true),
                                                                       .briefDescription(editable: true),
                                                                       .productType(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForAffiliateProduct() {
        // Arrange
        let product = Fixtures.affiliateProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true),
                                                                       .reviews,
                                                                       .externalURL(editable: true),
                                                                       .productType(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editSKU, .editCategories, .editTags, .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForGroupedProduct() {
        // Arrange
        let product = Fixtures.groupedProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.groupedProducts(editable: true), .reviews, .productType(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editSKU, .editCategories, .editTags, .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForVariableProductWithoutVariations() {
        // Arrange
        let product = Fixtures.variableProductWithoutVariations
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [
            .variations,
            .reviews,
            .shippingSettings(editable: true),
            .inventorySettings(editable: true),
            .productType(editable: true)
        ]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForVariableProductWithVariations() {
        // Arrange
        let product = Fixtures.variableProductWithVariations
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [
            .variations,
            .reviews,
            .shippingSettings(editable: true),
            .inventorySettings(editable: true),
            .productType(editable: true)
        ]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_actions_for_non_core_product_without_price() {
        // Arrange
        let product = Fixtures.nonCoreProductWithoutPrice
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.reviews, .inventorySettings(editable: false), .productType(editable: false)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_actions_for_non_core_product_with_price() {
        // Arrange
        let product = Fixtures.nonCoreProductWithPrice
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [
            .priceSettings(editable: false),
            .reviews,
            .inventorySettings(editable: false),
            .productType(editable: false)
        ]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }
}

private extension ProductFormActionsFactoryTests {
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
        // downloadable: false, virtual: true, reviews: false, with inventory/shipping/categories/tags/brief description
        static let physicalSimpleProductWithReviewsDisabled = MockProduct().product(downloadable: false,
                                                                                    briefDescription: "desc", productType: .simple,
                                                                                    manageStock: true, sku: "uks", stockQuantity: nil,
                                                                                    dimensions: ProductDimensions(length: "", width: "", height: ""),
                                                                                    weight: "2",
                                                                                    virtual: false,
                                                                                    reviewsAllowed: false,
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
        // Non-core product, missing price/brief description/categories/tags
        static let nonCoreProductWithoutPrice = MockProduct().product(briefDescription: "",
                                                                      productType: .custom("other")).copy(regularPrice: "")

        // Non-core product, missing brief description/categories/tags
        static let nonCoreProductWithPrice = MockProduct().product(briefDescription: "",
                                                                   productType: .custom("other")).copy(regularPrice: "2")
    }
}
