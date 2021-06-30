import XCTest
import Fakes

@testable import WooCommerce
@testable import Yosemite

final class ProductFormActionsFactoryTests: XCTestCase {
    func testViewModelForPhysicalSimpleProductWithoutImages() {
        // Arrange
        let product = Fixtures.physicalSimpleProductWithoutImages
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true, hideSeparator: false),
                                                                       .reviews,
                                                                       .shippingSettings(editable: true),
                                                                       .inventorySettings(editable: true),
                                                                       .categories(editable: true),
                                                                       .tags(editable: true),
                                                                       .shortDescription(editable: true),
                                                                       .linkedProducts(editable: true),
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
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true, hideSeparator: false),
                                                                       .reviews,
                                                                       .shippingSettings(editable: true),
                                                                       .inventorySettings(editable: true),
                                                                       .categories(editable: true),
                                                                       .tags(editable: true),
                                                                       .shortDescription(editable: true),
                                                                       .linkedProducts(editable: true),
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
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true, hideSeparator: false),
                                                                       .shippingSettings(editable: true),
                                                                       .inventorySettings(editable: true),
                                                                       .categories(editable: true),
                                                                       .tags(editable: true),
                                                                       .shortDescription(editable: true),
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_viewModel_for_product_without_linked_products_shows_editLinkedProducts_in_bottom_sheet() {
        // Arrange
        let product = Fixtures.physicalSimpleProductWithoutLinkedProducts
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true, hideSeparator: false),
                                                                       .shippingSettings(editable: true),
                                                                       .inventorySettings(editable: true),
                                                                       .categories(editable: true),
                                                                       .tags(editable: true),
                                                                       .shortDescription(editable: true),
                                                                       .productType(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editLinkedProducts]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_viewModel_for_product_with_linked_products_shows_linkedProducts_action_in_settings_section() {
        // Arrange
        let product = Fixtures.physicalSimpleProductWithImages
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true, hideSeparator: false),
                                                                       .reviews,
                                                                       .shippingSettings(editable: true),
                                                                       .inventorySettings(editable: true),
                                                                       .categories(editable: true),
                                                                       .tags(editable: true),
                                                                       .shortDescription(editable: true),
                                                                       .linkedProducts(editable: true),
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
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true, hideSeparator: false),
                                                                       .reviews,
                                                                       .inventorySettings(editable: true),
                                                                       .categories(editable: true),
                                                                       .tags(editable: true),
                                                                       .downloadableFiles(editable: true),
                                                                       .shortDescription(editable: true),
                                                                       .linkedProducts(editable: true),
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
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true, hideSeparator: false),
                                                                       .reviews,
                                                                       .inventorySettings(editable: true),
                                                                       .categories(editable: true),
                                                                       .tags(editable: true),
                                                                       .shortDescription(editable: true),
                                                                       .linkedProducts(editable: true),
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
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true, hideSeparator: false),
                                                                       .reviews,
                                                                       .externalURL(editable: true),
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editSKU, .editCategories, .editTags, .editShortDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForGroupedProduct() {
        // Arrange
        let product = Fixtures.groupedProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.groupedProducts(editable: true),
                                                                       .reviews,
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editSKU, .editCategories, .editTags, .editShortDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForVariableProductWithoutVariations() {
        // Arrange
        let product = Fixtures.variableProductWithoutVariations
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [
            .variations(hideSeparator: false),
            .reviews,
            .shippingSettings(editable: true),
            .inventorySettings(editable: true),
            .linkedProducts(editable: true),
            .productType(editable: true)
        ]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editShortDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForVariableProductWithVariations() {
        // Arrange
        let product = Fixtures.variableProductWithVariations
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [
            .variations(hideSeparator: true),
            .noPriceWarning,
            .reviews,
            .shippingSettings(editable: true),
            .inventorySettings(editable: true),
            .linkedProducts(editable: true),
            .productType(editable: true)
        ]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editShortDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_actions_for_non_core_product_without_price() {
        // Arrange
        let product = Fixtures.nonCoreProductWithoutPrice
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.reviews,
                                                                       .inventorySettings(editable: false),
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: false)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editShortDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_actions_for_non_core_product_with_price() {
        // Arrange
        let product = Fixtures.nonCoreProductWithPrice
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model, formType: .edit)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [
            .priceSettings(editable: false, hideSeparator: false),
            .reviews,
            .inventorySettings(editable: false),
            .linkedProducts(editable: true),
            .productType(editable: false)
        ]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editShortDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_actions_for_products_with_add_ons_while_feature_is_enabled() {
        // Given
        let products = [
            Fixtures.physicalSimpleProductWithImages.copy(addOns: [ProductAddOn.fake()]),
            Fixtures.affiliateProduct.copy(addOns: [ProductAddOn.fake()]),
            Fixtures.groupedProduct.copy(addOns: [ProductAddOn.fake()]),
            Fixtures.variableProductWithVariations.copy(addOns: [ProductAddOn.fake()]),
            Fixtures.nonCoreProductWithPrice.copy(addOns: [ProductAddOn.fake()])
        ]

        products.forEach { product in
            let model = EditableProductModel(product: product)

            // When
            let factory = ProductFormActionsFactory(product: model, formType: .edit, addOnsFeatureEnabled: true)

            // Then
            let containsAddOnAction = factory.settingsSectionActions().contains(ProductFormEditAction.addOns(editable: true))
            XCTAssertTrue(containsAddOnAction)
        }
    }

    func test_actions_for_products_with_add_ons_while_feature_is_disabled() {
        // Given
        let products = [
            Fixtures.physicalSimpleProductWithImages.copy(addOns: [ProductAddOn.fake()]),
            Fixtures.affiliateProduct.copy(addOns: [ProductAddOn.fake()]),
            Fixtures.groupedProduct.copy(addOns: [ProductAddOn.fake()]),
            Fixtures.variableProductWithVariations.copy(addOns: [ProductAddOn.fake()]),
            Fixtures.nonCoreProductWithPrice.copy(addOns: [ProductAddOn.fake()])
        ]

        products.forEach { product in
            let model = EditableProductModel(product: product)

            // When
            let factory = ProductFormActionsFactory(product: model, formType: .edit, addOnsFeatureEnabled: false)

            // Then
            let containsAddOnAction = factory.settingsSectionActions().contains(ProductFormEditAction.addOns(editable: true))
            XCTAssertFalse(containsAddOnAction)
        }
    }

    func test_actions_for_products_with_no_add_ons_while_feature_is_enabled() {
        // Given
        let products = [
            Fixtures.physicalSimpleProductWithImages.copy(addOns: []),
            Fixtures.affiliateProduct.copy(addOns: []),
            Fixtures.groupedProduct.copy(addOns: []),
            Fixtures.variableProductWithVariations.copy(addOns: []),
            Fixtures.nonCoreProductWithPrice.copy(addOns: [])
        ]

        products.forEach { product in
            let model = EditableProductModel(product: product)

            // When
            let factory = ProductFormActionsFactory(product: model, formType: .edit, addOnsFeatureEnabled: false)

            // Then
            let containsAddOnAction = factory.settingsSectionActions().contains(ProductFormEditAction.addOns(editable: true))
            XCTAssertFalse(containsAddOnAction)
        }
    }

    func test_actions_for_variable_product_with_variations_price_not_set_contains_noPriceWarning_action() {
        // Given
        let product = Fixtures.variableProductWithVariations.copy(price: "")
        let model = EditableProductModel(product: product)

        // When
        let factory = ProductFormActionsFactory(product: model, formType: .edit, variationsPrice: .notSet)

        // Then
        let containsWarningAction = factory.settingsSectionActions().contains(ProductFormEditAction.noPriceWarning)
        XCTAssertTrue(containsWarningAction)
    }

    func test_actions_for_variable_product_with_variations_price_set_does_not_contains_noPriceWarning_action() {
        // Given
        let product = Fixtures.variableProductWithVariations.copy(price: "")
        let model = EditableProductModel(product: product)

        // When
        let factory = ProductFormActionsFactory(product: model, formType: .edit, variationsPrice: .set)

        // Then
        let containsWarningAction = factory.settingsSectionActions().contains(ProductFormEditAction.noPriceWarning)
        XCTAssertFalse(containsWarningAction)
    }

    func test_actions_for_variable_product_with_no_product_price_set_contains_noPriceWarning_action() {
        // Given
        let product = Fixtures.variableProductWithVariations.copy(price: "")
        let model = EditableProductModel(product: product)

        // When
        let factory = ProductFormActionsFactory(product: model, formType: .edit, variationsPrice: .unknown)

        // Then
        let containsWarningAction = factory.settingsSectionActions().contains(ProductFormEditAction.noPriceWarning)
        XCTAssertTrue(containsWarningAction)
    }

    func test_actions_for_variable_product_with_product_price_set_contains_noPriceWarning_action() {
        // Given
        let product = Fixtures.variableProductWithVariations.copy(price: "10.12")
        let model = EditableProductModel(product: product)

        // When
        let factory = ProductFormActionsFactory(product: model, formType: .edit, variationsPrice: .unknown)

        // Then
        let containsWarningAction = factory.settingsSectionActions().contains(ProductFormEditAction.noPriceWarning)
        XCTAssertFalse(containsWarningAction)
    }

    func test_actions_for_variable_product_with_attributes_contains_attributes_action() {
        // Given
        let product = Fixtures.variableProductWithVariations.copy(attributes: [
            ProductAttribute.fake().copy(variation: true)
        ])
        let model = EditableProductModel(product: product)

        // When
        let factory = ProductFormActionsFactory(product: model, formType: .edit, variationsPrice: .unknown)

        // Then
        let containsAttributeAction = factory.settingsSectionActions().contains(ProductFormEditAction.attributes(editable: true))
        XCTAssertTrue(containsAttributeAction)
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
        // downloadable: false, virtual: false, with inventory/shipping/categories/tags/short description
        static let physicalSimpleProductWithoutImages = Fakes.ProductFactory.simpleProductWithNoImages()

        // downloadable: false, virtual: true, with inventory/shipping/categories/tags/short description
        static let physicalSimpleProductWithImages = physicalSimpleProductWithoutImages.copy(images: [image])

        // downloadable: false, virtual: true, reviews: false, with inventory/shipping/categories/tags/short description
        static let physicalSimpleProductWithReviewsDisabled = physicalSimpleProductWithImages.copy(reviewsAllowed: false)

        // downloadable: false, virtual: true, reviews: false, with inventory/shipping/categories/tags/short description
        static let physicalSimpleProductWithoutLinkedProducts = physicalSimpleProductWithReviewsDisabled.copy(upsellIDs: [], crossSellIDs: [])

        // downloadable: false, virtual: true, with inventory/shipping/categories/tags/short description
        static let virtualSimpleProduct = physicalSimpleProductWithoutImages.copy(virtual: true)

        // downloadable: true, virtual: true, missing inventory/shipping/categories/short description
        static let downloadableSimpleProduct = virtualSimpleProduct.copy(downloadable: true)

        // Affiliate product, missing external URL/sku/inventory/short description/categories/tags
        static let affiliateProduct = physicalSimpleProductWithoutImages.copy(productTypeKey: ProductType.affiliate.rawValue,
                                                                              shortDescription: "",
                                                                              sku: "",
                                                                              externalURL: "",
                                                                              categories: [],
                                                                              tags: [])

        // Grouped product, missing grouped products/sku/short description/categories/tags
        static let groupedProduct = affiliateProduct.copy(productTypeKey: ProductType.grouped.rawValue)

        // Variable product, missing variations/short description/categories/tags
        static let variableProductWithoutVariations = affiliateProduct.copy(productTypeKey: ProductType.variable.rawValue, variations: [])

        // Variable product with one variation, missing short description/categories/tags
        static let variableProductWithVariations = variableProductWithoutVariations.copy(variations: [123])

        // Non-core product, missing price/short description/categories/tags
        static let nonCoreProductWithoutPrice = affiliateProduct.copy(productTypeKey: "other", regularPrice: "")

        // Non-core product, missing short description/categories/tags
        static let nonCoreProductWithPrice = nonCoreProductWithoutPrice.copy(regularPrice: "2")
    }
}
