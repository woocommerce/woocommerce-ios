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
        let name = EditableProductVariationModel(productVariation: variation, allAttributes: allAttributes, parentProductSKU: nil).name

        // Assert
        let expectedName = [
            "Orange",
            String.localizedStringWithFormat(EditableProductVariationModel.Localization.anyAttributeFormat, "Brand")
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
        let name = EditableProductVariationModel(productVariation: variation, allAttributes: allAttributes, parentProductSKU: nil).name

        // Assert
        let expectedName = ["Orange", "House"].joined(separator: " - ")
        XCTAssertEqual(name, expectedName)
    }

    // MARK: - `isEnabled`

    func test_a_variation_is_enabled_with_publish_status() {
        // Arrange
        let variation = MockProductVariation().productVariation().copy(status: .publish)

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
        let variation = MockProductVariation().productVariation().copy(status: .publish, regularPrice: nil)

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
        let model = EditableProductVariationModel(productVariation: variation, allAttributes: [], parentProductSKU: sku)

        // Assert
        XCTAssertNil(model.sku)
        XCTAssertNil(model.productVariation.sku)
    }

    func test_a_variation_with_a_different_sku_from_parent_product_has_the_same_sku_after_form_model_init() {
        // Arrange
        let sku = "orange-pen"
        let variation = MockProductVariation().productVariation().copy(sku: sku)

        // Action
        let model = EditableProductVariationModel(productVariation: variation, allAttributes: [], parentProductSKU: "")

        // Assert
        XCTAssertEqual(model.sku, sku)
        XCTAssertEqual(model.productVariation.sku, sku)
    }
}
