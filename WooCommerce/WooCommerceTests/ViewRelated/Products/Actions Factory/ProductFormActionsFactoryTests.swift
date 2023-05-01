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
        let factory = Fixtures.actionsFactory(product: model, formType: .edit)

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
        let factory = Fixtures.actionsFactory(product: model, formType: .edit)

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
        let factory = Fixtures.actionsFactory(product: model, formType: .edit)

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
        let factory = Fixtures.actionsFactory(product: model, formType: .edit)

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
        let factory = Fixtures.actionsFactory(product: model, formType: .edit)

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
        let factory = Fixtures.actionsFactory(product: model, formType: .edit)

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

    func test_view_model_for_simple_product_with_downloadable_files_action_not_setting_based_and_has_no_files() {
        // Arrange
        let product = Fixtures.virtualSimpleProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = Fixtures.actionsFactory(product: model, formType: .edit, isDownloadableFilesSettingBased: false)

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

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editDownloadableFiles]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_view_model_for_simple_product_with_downloadable_files_action_not_setting_based_and_has_files() {
        // Arrange
        let product = Fixtures.virtualSimpleProduct.copy(downloadable: true, downloads: [.fake()])
        let model = EditableProductModel(product: product)

        // Action
        let factory = Fixtures.actionsFactory(product: model, formType: .edit, isDownloadableFilesSettingBased: false)

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
        let factory = Fixtures.actionsFactory(product: model, formType: .edit)

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
        let factory = Fixtures.actionsFactory(product: model, formType: .edit)

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
        let factory = Fixtures.actionsFactory(product: model, formType: .edit)

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
        let factory = Fixtures.actionsFactory(product: model, formType: .edit)

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
        let factory = Fixtures.actionsFactory(product: model, formType: .edit)

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
        let factory = Fixtures.actionsFactory(product: model, formType: .edit)

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
        let factory = Fixtures.actionsFactory(product: model, formType: .edit)

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

    func test_settings_actions_hides_empty_reviews_when_feature_is_enabled() {
        // Given
        let product = Fixtures.physicalSimpleProductWithoutImages
        let model = EditableProductModel(product: product)

        // When
        let factory = ProductFormActionsFactory(product: model, formType: .edit, isEmptyReviewsOptionHidden: true)

        // Then
        XCTAssertFalse(factory.settingsSectionActions().contains(.reviews))
        XCTAssertTrue(factory.bottomSheetActions().contains(.editReviews))
    }

    func test_bottom_sheet_actions_shows_variation_option_when_feature_is_enabled() {
        // Given
        let product = Fixtures.physicalSimpleProductWithoutImages
        let model = EditableProductModel(product: product)

        // When
        let factory = ProductFormActionsFactory(product: model, formType: .edit, isConvertToVariableOptionEnabled: true)

        // Then
        XCTAssertFalse(factory.settingsSectionActions().contains(.convertToVariable))
        XCTAssertTrue(factory.bottomSheetActions().contains(.convertToVariable))
    }

    func test_settings_actions_does_not_contain_product_type_when_it_is_disabled() {
        // Given
        let product = Fixtures.physicalSimpleProductWithoutImages
        let model = EditableProductModel(product: product)

        // When
        let factory = ProductFormActionsFactory(product: model, formType: .edit, isProductTypeActionEnabled: false)

        // Then
        XCTAssertFalse(factory.settingsSectionActions().contains(.productType(editable: true)))
    }

    func test_settings_actions_contain_even_empty_categories_when_it_is_enabled() {
        // Given
        let product = Product.fake()
        let model = EditableProductModel(product: product)

        // When
        let factory = ProductFormActionsFactory(product: model, formType: .edit, isCategoriesActionAlwaysEnabled: true)

        // Then
        XCTAssertFalse(product.categories.isNotEmpty)
        XCTAssertTrue(factory.settingsSectionActions().contains(.categories(editable: true)))
    }

    func test_options_CTA_actions_for_simple_product_contain_add_options_when_it_is_enabled() {
        // Given
        let product = Fixtures.physicalSimpleProductWithoutImages
        let model = EditableProductModel(product: product)

        // When
        let factory = ProductFormActionsFactory(product: model, formType: .edit, isAddOptionsButtonEnabled: true)

        // Then
        XCTAssertTrue(factory.optionsCTASectionActions().contains(.addOptions))
    }

    func test_options_CTA_actions_for_non_simple_products_do_not_contain_add_options_when_it_is_enabled() {
        // Given
        let products = [
            Fixtures.affiliateProduct,
            Fixtures.groupedProduct,
            Fixtures.variableProductWithoutVariations,
            Fixtures.nonCoreProductWithPrice
        ]

        products.forEach { product in
            let model = EditableProductModel(product: product)

            // When
            let factory = ProductFormActionsFactory(product: model, formType: .edit, isAddOptionsButtonEnabled: true)

            // Then
            XCTAssertFalse(factory.optionsCTASectionActions().contains(.addOptions))
        }
    }

    func test_view_model_for_bundle_product_with_feature_flag_disabled() {
        // Arrange
        let product = Fixtures.bundleProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = Fixtures.actionsFactory(product: model, formType: .edit, isBundledProductsEnabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        assertEqual(expectedPrimarySectionActions, factory.primarySectionActions())

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.reviews,
                                                                       .inventorySettings(editable: false),
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: false)]
        assertEqual(expectedSettingsSectionActions, factory.settingsSectionActions())

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editShortDescription]
        assertEqual(expectedBottomSheetActions, factory.bottomSheetActions())
    }

    func test_view_model_for_bundle_product_without_price_or_bundled_items_with_feature_flag_enabled() {
        // Arrange
        let product = Fixtures.bundleProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = Fixtures.actionsFactory(product: model, formType: .edit, isBundledProductsEnabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        assertEqual(expectedPrimarySectionActions, factory.primarySectionActions())

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.bundledProducts(actionable: false),
                                                                       .reviews,
                                                                       .inventorySettings(editable: false),
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: false)]
        assertEqual(expectedSettingsSectionActions, factory.settingsSectionActions())

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editShortDescription]
        assertEqual(expectedBottomSheetActions, factory.bottomSheetActions())
    }

    func test_view_model_for_bundle_product_with_price_and_bundled_items_with_feature_flag_enabled() {
        // Arrange
        let product = Fixtures.bundleProduct.copy(regularPrice: "2", bundledItems: [.fake()])
        let model = EditableProductModel(product: product)

        // Action
        let factory = Fixtures.actionsFactory(product: model, formType: .edit, isBundledProductsEnabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        assertEqual(expectedPrimarySectionActions, factory.primarySectionActions())

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.bundledProducts(actionable: true),
                                                                       .priceSettings(editable: false, hideSeparator: false),
                                                                       .reviews,
                                                                       .inventorySettings(editable: false),
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: false)]
        assertEqual(expectedSettingsSectionActions, factory.settingsSectionActions())

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editShortDescription]
        assertEqual(expectedBottomSheetActions, factory.bottomSheetActions())
    }

    func test_view_model_for_composite_product_with_feature_flag_disabled() {
        // Arrange
        let product = Fixtures.compositeProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = Fixtures.actionsFactory(product: model, formType: .edit, isCompositeProductsEnabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        assertEqual(expectedPrimarySectionActions, factory.primarySectionActions())

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: false, hideSeparator: false),
                                                                       .reviews,
                                                                       .inventorySettings(editable: false),
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: false)]
        assertEqual(expectedSettingsSectionActions, factory.settingsSectionActions())

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editShortDescription]
        assertEqual(expectedBottomSheetActions, factory.bottomSheetActions())
    }

    func test_view_model_for_composite_product_with_feature_flag_enabled() {
        // Arrange
        let product = Fixtures.compositeProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = Fixtures.actionsFactory(product: model, formType: .edit, isCompositeProductsEnabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        assertEqual(expectedPrimarySectionActions, factory.primarySectionActions())

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.components(actionable: true),
                                                                       .priceSettings(editable: false, hideSeparator: false),
                                                                       .reviews,
                                                                       .inventorySettings(editable: false),
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: false)]
        assertEqual(expectedSettingsSectionActions, factory.settingsSectionActions())

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editShortDescription]
        assertEqual(expectedBottomSheetActions, factory.bottomSheetActions())
    }

    func test_view_model_for_subscription_product_with_feature_flag_disabled() {
        // Arrange
        let product = Fixtures.subscriptionProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = Fixtures.actionsFactory(product: model, formType: .edit, isSubscriptionProductsEnabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        assertEqual(expectedPrimarySectionActions, factory.primarySectionActions())

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: false, hideSeparator: false),
                                                                       .reviews,
                                                                       .inventorySettings(editable: false),
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: false)]
        assertEqual(expectedSettingsSectionActions, factory.settingsSectionActions())

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editShortDescription]
        assertEqual(expectedBottomSheetActions, factory.bottomSheetActions())
    }

    func test_view_model_for_subscription_product_with_feature_flag_enabled() {
        // Arrange
        let product = Fixtures.subscriptionProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = Fixtures.actionsFactory(product: model, formType: .edit, isSubscriptionProductsEnabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        assertEqual(expectedPrimarySectionActions, factory.primarySectionActions())

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.subscription(actionable: true),
                                                                       .reviews,
                                                                       .inventorySettings(editable: false),
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: false)]
        assertEqual(expectedSettingsSectionActions, factory.settingsSectionActions())

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editShortDescription]
        assertEqual(expectedBottomSheetActions, factory.bottomSheetActions())
    }

    func test_view_model_for_variable_subscription_product_with_feature_flag_disabled() {
        // Arrange
        let product = Fixtures.variableSubscriptionProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = Fixtures.actionsFactory(product: model, formType: .edit, isSubscriptionProductsEnabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        assertEqual(expectedPrimarySectionActions, factory.primarySectionActions())

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.reviews,
                                                                       .inventorySettings(editable: false),
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: false)]
        assertEqual(expectedSettingsSectionActions, factory.settingsSectionActions())

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editShortDescription]
        assertEqual(expectedBottomSheetActions, factory.bottomSheetActions())
    }

    func test_view_model_for_variable_subscription_product_with_no_variations_and_feature_flag_enabled() {
        // Arrange
        let product = Fixtures.variableSubscriptionProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = Fixtures.actionsFactory(product: model, formType: .edit, isSubscriptionProductsEnabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        assertEqual(expectedPrimarySectionActions, factory.primarySectionActions())

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.noVariationsWarning,
                                                                       .reviews,
                                                                       .inventorySettings(editable: false),
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: false)]
        assertEqual(expectedSettingsSectionActions, factory.settingsSectionActions())

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editShortDescription]
        assertEqual(expectedBottomSheetActions, factory.bottomSheetActions())
    }

    func test_view_model_for_variable_subscription_product_with_variations_and_feature_flag_enabled() {
        // Arrange
        let product = Fixtures.variableSubscriptionProduct.copy(attributes: [.fake().copy(variation: true)], variations: [123])
        let model = EditableProductModel(product: product)

        // Action
        let factory = Fixtures.actionsFactory(product: model, formType: .edit, isSubscriptionProductsEnabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        assertEqual(expectedPrimarySectionActions, factory.primarySectionActions())

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.variations(hideSeparator: false),
                                                                       .attributes(editable: true),
                                                                       .reviews,
                                                                       .inventorySettings(editable: false),
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: false)]
        assertEqual(expectedSettingsSectionActions, factory.settingsSectionActions())

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editCategories, .editTags, .editShortDescription]
        assertEqual(expectedBottomSheetActions, factory.bottomSheetActions())
    }

    func test_viewModel_for_product_with_min_max_quantities_shows_quantity_rules_row_in_settings_section() {
        // Arrange
        let product = Fixtures.physicalSimpleProductWithImages.copy(minAllowedQuantity: "4",
                                                                    maxAllowedQuantity: "200",
                                                                    groupOfQuantity: "4")
        let model = EditableProductModel(product: product)

        // Action
        let factory = Fixtures.actionsFactory(product: model, formType: .edit, isMinMaxQuantitiesEnabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .name(editable: true), .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true, hideSeparator: false),
                                                                       .reviews,
                                                                       .shippingSettings(editable: true),
                                                                       .inventorySettings(editable: true),
                                                                       .quantityRules,
                                                                       .categories(editable: true),
                                                                       .tags(editable: true),
                                                                       .shortDescription(editable: true),
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
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

        // Bundle product, missing price/short description/categories/tags
        static let bundleProduct = affiliateProduct.copy(productTypeKey: ProductType.bundle.rawValue)

        // Composite product with price and composite components
        static let compositeProduct = affiliateProduct.copy(productTypeKey: ProductType.composite.rawValue, regularPrice: "2", compositeComponents: [.fake()])

        // Subscription product with price and subscription
        static let subscriptionProduct = affiliateProduct.copy(productTypeKey: ProductType.subscription.rawValue, regularPrice: "2", subscription: .fake())

        // Variable subscription product with no variations or variation attributes
        static let variableSubscriptionProduct = affiliateProduct.copy(productTypeKey: ProductType.variableSubscription.rawValue)

        // Non-core product, missing price/short description/categories/tags
        static let nonCoreProductWithoutPrice = affiliateProduct.copy(productTypeKey: "other", regularPrice: "")

        // Non-core product, missing short description/categories/tags
        static let nonCoreProductWithPrice = nonCoreProductWithoutPrice.copy(regularPrice: "2")

        // Factory with default feature settings
        static func actionsFactory(product: EditableProductModel,
                                   formType: ProductFormType,
                                   addOnsFeatureEnabled: Bool = false,
                                   isLinkedProductsPromoEnabled: Bool = false,
                                   isAddOptionsButtonEnabled: Bool = false,
                                   isConvertToVariableOptionEnabled: Bool = false,
                                   isEmptyReviewsOptionHidden: Bool = false,
                                   isProductTypeActionEnabled: Bool = true,
                                   isCategoriesActionAlwaysEnabled: Bool = false,
                                   isDownloadableFilesSettingBased: Bool = true,
                                   isBundledProductsEnabled: Bool = false,
                                   isCompositeProductsEnabled: Bool = false,
                                   isSubscriptionProductsEnabled: Bool = false,
                                   isMinMaxQuantitiesEnabled: Bool = false,
                                   variationsPrice: ProductFormActionsFactory.VariationsPrice = .unknown) -> ProductFormActionsFactory {
            ProductFormActionsFactory(product: product,
                                      formType: formType,
                                      addOnsFeatureEnabled: addOnsFeatureEnabled,
                                      isLinkedProductsPromoEnabled: isLinkedProductsPromoEnabled,
                                      isAddOptionsButtonEnabled: isAddOptionsButtonEnabled,
                                      isConvertToVariableOptionEnabled: isConvertToVariableOptionEnabled,
                                      isEmptyReviewsOptionHidden: isEmptyReviewsOptionHidden,
                                      isProductTypeActionEnabled: isProductTypeActionEnabled,
                                      isCategoriesActionAlwaysEnabled: isCategoriesActionAlwaysEnabled,
                                      isDownloadableFilesSettingBased: isDownloadableFilesSettingBased,
                                      isBundledProductsEnabled: isBundledProductsEnabled,
                                      isCompositeProductsEnabled: isCompositeProductsEnabled,
                                      isSubscriptionProductsEnabled: isSubscriptionProductsEnabled,
                                      isMinMaxQuantitiesEnabled: isMinMaxQuantitiesEnabled,
                                      variationsPrice: variationsPrice)
        }
    }
}
