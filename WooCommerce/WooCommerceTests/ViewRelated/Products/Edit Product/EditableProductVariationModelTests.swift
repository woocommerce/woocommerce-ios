import XCTest
@testable import WooCommerce
@testable import Yosemite

final class EditableProductVariationModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 123456

    // MARK: - `name`

    func test_a_variation_with_any_attribute_has_name_that_consists_of_all_attributes() {
        // Arrange
        let allAttributes: [ProductAttribute] = [
            ProductAttribute(siteID: sampleSiteID, attributeID: 0, name: "Brand", position: 1, visible: true, variation: true, options: ["Unknown", "House"]),
            ProductAttribute(siteID: sampleSiteID, attributeID: 0, name: "Color", position: 0, visible: true, variation: true, options: ["Orange", "Green"])
        ]
        // The variation only has one attribute specified - Color.
        let variationAttributes: [ProductVariationAttribute] = [
            ProductVariationAttribute(id: 0, name: "Color", option: "Orange")
        ]
        let variation = MockProductVariation().productVariation().copy(attributes: variationAttributes)

        // Action
        let name = EditableProductVariationModel(productVariation: variation,
                                                 parentProductType: .variable,
                                                 allAttributes: allAttributes,
                                                 parentProductSKU: nil,
                                                 parentProductDisablesQuantityRules: nil).name

        // Assert
        let expectedName = [
            "Orange",
            String.localizedStringWithFormat(VariationAttributeViewModel.Localization.anyAttributeFormat, "Brand")
        ].joined(separator: " - ")
        XCTAssertEqual(name, expectedName)
    }

    func test_a_variation_with_full_attributes_has_name_that_consists_of_all_attributes() {
        // Arrange
        let allAttributes: [ProductAttribute] = [
            ProductAttribute(siteID: sampleSiteID, attributeID: 0, name: "Brand", position: 1, visible: true, variation: true, options: ["Unknown", "House"]),
            ProductAttribute(siteID: sampleSiteID, attributeID: 0, name: "Color", position: 0, visible: true, variation: true, options: ["Orange", "Green"])
        ]
        // The variation has both attributes.
        let variationAttributes: [ProductVariationAttribute] = [
            ProductVariationAttribute(id: 0, name: "Brand", option: "House"),
            ProductVariationAttribute(id: 0, name: "Color", option: "Orange")
        ]
        let variation = MockProductVariation().productVariation().copy(attributes: variationAttributes)

        // Action
        let name = EditableProductVariationModel(productVariation: variation,
                                                 parentProductType: .variable,
                                                 allAttributes: allAttributes,
                                                 parentProductSKU: nil,
                                                 parentProductDisablesQuantityRules: nil).name

        // Assert
        let expectedName = ["Orange", "House"].joined(separator: " - ")
        XCTAssertEqual(name, expectedName)
    }

    // MARK: - `isEnabled`

    func test_a_variation_is_enabled_with_publish_status() {
        // Arrange
        let variation = MockProductVariation().productVariation().copy(status: .published)

        // Action
        let model = EditableProductVariationModel(productVariation: variation)

        // Assert
        XCTAssertTrue(model.isEnabled)
    }

    func test_a_variation_is_disabled_with_private_status() {
        // Arrange
        let variation = MockProductVariation().productVariation().copy(status: .privateStatus)

        // Action
        let model = EditableProductVariationModel(productVariation: variation)

        // Assert
        XCTAssertFalse(model.isEnabled)
    }

    func test_a_variation_is_disabled_with_other_status() {
        // Arrange
        let variation = MockProductVariation().productVariation().copy(status: .pending)

        // Action
        let model = EditableProductVariationModel(productVariation: variation)

        // Assert
        XCTAssertFalse(model.isEnabled)
    }

    // MARK: - `isEnabledAndMissingPrice`

    func test_a_variation_is_enabled_and_missing_price() {
        // Arrange
        let variation = MockProductVariation().productVariation().copy(status: .published, regularPrice: nil)

        // Action
        let model = EditableProductVariationModel(productVariation: variation)

        // Assert
        XCTAssertTrue(model.isEnabledAndMissingPrice)
    }

    func test_a_variation_is_not_enabled_and_missing_price_when_it_is_disabled() {
        // Arrange
        let variation = MockProductVariation().productVariation().copy(status: .privateStatus, regularPrice: nil)

        // Action
        let model = EditableProductVariationModel(productVariation: variation)

        // Assert
        XCTAssertFalse(model.isEnabledAndMissingPrice)
    }

    func test_a_variation_is_not_enabled_and_missing_price_when_it_is_enabled_and_has_a_price() {
        // Arrange
        let variation = MockProductVariation().productVariation().copy(status: .privateStatus, regularPrice: "6")

        // Action
        let model = EditableProductVariationModel(productVariation: variation)

        // Assert
        XCTAssertFalse(model.isEnabledAndMissingPrice)
    }

    // MARK: - `sku`

    func test_a_variation_with_the_same_sku_as_parent_product_has_nil_sku_after_form_model_init() {
        // Arrange
        let sku = "orange-pen"
        let variation = MockProductVariation().productVariation().copy(sku: sku)

        // Action
        let model = EditableProductVariationModel(productVariation: variation,
                                                  parentProductType: .variable,
                                                  allAttributes: [],
                                                  parentProductSKU: sku,
                                                  parentProductDisablesQuantityRules: nil)

        // Assert
        XCTAssertNil(model.sku)
        XCTAssertNil(model.productVariation.sku)
    }

    func test_a_variation_with_a_different_sku_from_parent_product_has_the_same_sku_after_form_model_init() {
        // Arrange
        let sku = "orange-pen"
        let variation = MockProductVariation().productVariation().copy(sku: sku)

        // Action
        let model = EditableProductVariationModel(productVariation: variation,
                                                  parentProductType: .variable,
                                                  allAttributes: [],
                                                  parentProductSKU: "",
                                                  parentProductDisablesQuantityRules: nil)

        // Assert
        XCTAssertEqual(model.sku, sku)
        XCTAssertEqual(model.productVariation.sku, sku)
    }

    // MARK: - `subscription`

    func test_it_sets_default_values_for_subscription_when_given_variation_has_nil_subscription_and_parentProductType_is_variableSubscription() {
        // Given
        let variation = MockProductVariation().productVariation().copy(subscription: nil)

        // When
        let model = EditableProductVariationModel(productVariation: variation,
                                                  parentProductType: .variableSubscription,
                                                  allAttributes: [],
                                                  parentProductSKU: nil,
                                                  parentProductDisablesQuantityRules: nil)

        // Then
        XCTAssertEqual(model.productVariation.subscription, .empty)
    }

    func test_it_does_not_alter_subscription_value_when_parentProductType_is_not_variableSubscription() {
        // Given
        let mockSubscription = ProductSubscription.fake().copy(price: "10")
        let variation = MockProductVariation().productVariation().copy(subscription: mockSubscription)

        // When
        let model = EditableProductVariationModel(productVariation: variation,
                                                  parentProductType: .variable,
                                                  allAttributes: [],
                                                  parentProductSKU: nil,
                                                  parentProductDisablesQuantityRules: nil)

        // Then
        XCTAssertEqual(model.productVariation.subscription, mockSubscription)
    }

    func test_it_does_not_alter_subscription_value_when_given_variation_has_non_nil_subscription() {
        // Given
        let mockSubscription = ProductSubscription.fake().copy(price: "10")
        let variation = MockProductVariation().productVariation().copy(subscription: mockSubscription)

        // When
        let model = EditableProductVariationModel(productVariation: variation,
                                                  parentProductType: .variableSubscription,
                                                  allAttributes: [],
                                                  parentProductSKU: nil,
                                                  parentProductDisablesQuantityRules: nil)

        // Then
        XCTAssertEqual(model.productVariation.subscription, mockSubscription)
    }

    // MARK: - `hasQuantityRules`

    func test_canEditQuantityRules_is_false_for_a_variation_with_nil_quantity_rules() {
        // Arrange
        let variation = ProductVariation.fake()

        // Action
        let model = EditableProductVariationModel(productVariation: variation)

        // Assert
        XCTAssertFalse(model.canEditQuantityRules)
    }

    func test_canEditQuantityRules_is_true_for_a_variation_with_empty_quantity_rules_that_overrides_product_quantities() {
        // Arrange
        let variation = ProductVariation.fake().copy(minAllowedQuantity: "", maxAllowedQuantity: "", groupOfQuantity: "", overrideProductQuantities: true)

        // Action
        let model = EditableProductVariationModel(productVariation: variation,
                                                  parentProductType: .variable,
                                                  allAttributes: [],
                                                  parentProductSKU: nil,
                                                  parentProductDisablesQuantityRules: true)

        // Assert
        XCTAssertFalse(model.canEditQuantityRules)
    }

    func test_canEditQuantityRules_is_false_for_a_variation_that_does_not_override_product_quantities() {
        // Arrange
        let variation = ProductVariation.fake().copy(minAllowedQuantity: "4", maxAllowedQuantity: "30", groupOfQuantity: "2", overrideProductQuantities: false)

        // Action
        let model = EditableProductVariationModel(productVariation: variation,
                                                  parentProductType: .variable,
                                                  allAttributes: [],
                                                  parentProductSKU: nil,
                                                  parentProductDisablesQuantityRules: false)

        // Assert
        XCTAssertFalse(model.canEditQuantityRules)
    }

    func test_canEditQuantityRules_is_true_for_a_variation_that_does_override_product_quantities_and_has_quantity_rules() {
        // Arrange
        let variation = ProductVariation.fake().copy(minAllowedQuantity: "4", maxAllowedQuantity: "30", groupOfQuantity: "2", overrideProductQuantities: true)

        // Action
        let model = EditableProductVariationModel(productVariation: variation,
                                                  parentProductType: .variable,
                                                  allAttributes: [],
                                                  parentProductSKU: nil,
                                                  parentProductDisablesQuantityRules: false)

        // Assert
        XCTAssertTrue(model.canEditQuantityRules)
    }

    func test_canEditQuantityRules_is_false_when_parent_product_disables_quantity_rules() {
        // Arrange
        let variation = ProductVariation.fake().copy(minAllowedQuantity: "4", maxAllowedQuantity: "30", groupOfQuantity: "2", overrideProductQuantities: true)

        // Action
        let model = EditableProductVariationModel(productVariation: variation,
                                                  parentProductType: .variable,
                                                  allAttributes: [],
                                                  parentProductSKU: nil,
                                                  parentProductDisablesQuantityRules: true)

        // Assert
        XCTAssertFalse(model.canEditQuantityRules)
    }
}
