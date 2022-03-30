import XCTest
import Yosemite
@testable import WooCommerce

final class ProductVariationFormatterTests: XCTestCase {

    func test_generateName_returns_expected_name_from_single_attribute() {
        // Given
        let productAttributes = [ProductAttribute.fake().copy(attributeID: 1, name: "Color")]
        let variation = ProductVariation.fake().copy(attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")])

        // When
        let name = ProductVariationFormatter().generateName(for: variation, from: productAttributes)

        // Then
        XCTAssertEqual(name, "Blue")
    }

    func test_generateName_returns_expected_name_from_multiple_attributes() {
        // Given
        let productAttributes = [ProductAttribute.fake().copy(attributeID: 1, name: "Color"), ProductAttribute.fake().copy(attributeID: 2, name: "Size")]
        let variation = ProductVariation.fake().copy(attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")])

        // When
        let name = ProductVariationFormatter().generateName(for: variation, from: productAttributes)

        // Then
        XCTAssertEqual(name, "Blue - Any Size")
    }

    func test_generateAttributes_returns_expected_attributes() {
        // Given
        let productAttributes = [ProductAttribute.fake().copy(attributeID: 1, name: "Color"), ProductAttribute.fake().copy(attributeID: 2, name: "Size")]
        let variation = ProductVariation.fake().copy(attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")])

        // When
        let attributes = ProductVariationFormatter().generateAttributes(for: variation, from: productAttributes)

        // Then
        let expectedColorAttribute = VariationAttributeViewModel(name: "Color", value: "Blue")
        let expectedSizeAttribute = VariationAttributeViewModel(name: "Size")
        XCTAssertEqual(attributes, [expectedColorAttribute, expectedSizeAttribute])
    }
}
