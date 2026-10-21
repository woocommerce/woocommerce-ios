import XCTest
import Experiments
@testable import WooCommerce
@testable import Yosemite

final class EditAttributesViewModelTests: XCTestCase {

    func test_done_button_is_visible_when_allowing_variation_creation() {
        // Given, Then
        let viewModel = EditAttributesViewModel(product: .fake(), allowVariationCreation: true, featureFlagService: MockFeatureFlagService())

        // Then
        XCTAssertTrue(viewModel.showDoneButton)
    }

    func test_done_button_is_not_visible_when_not_allowing_variation_creation() {
        // Given, Then
        let viewModel = EditAttributesViewModel(product: .fake(), allowVariationCreation: false, featureFlagService: MockFeatureFlagService())

        // Then
        XCTAssertFalse(viewModel.showDoneButton)
    }

    func test_product_attributes_are_correctly_converted_into_view_models() {
        // Given
        let attribute = sampleAttribute(name: "attr", options: ["Option 1", "Option 2"])
        let attribute2 = sampleNonVariationAttribute(name: "attr-extra", options: ["Option X", "Option Y"])
        let product = Product.fake().copy(attributes: [attribute, attribute2])

        // When
        let viewModel = EditAttributesViewModel(product: product, allowVariationCreation: false, featureFlagService: MockFeatureFlagService())

        // Then
        let expectedVM = ImageAndTitleAndTextTableViewCell.ViewModel(title: "attr",
                                                                     text: "Option 1, Option 2",
                                                                     numberOfLinesForTitle: 0,
                                                                     numberOfLinesForText: 0)
        XCTAssertEqual(viewModel.attributes, [expectedVM])
    }

    func test_product_attributes_are_recreated_after_updating_the_product() {
        // Given
        let attribute = sampleAttribute(name: "attr", options: ["Option 1", "Option 2"])
        let attribute2 = sampleAttribute(name: "attr-2", options: ["Option 3", "Option 4"])
        let attribute3 = sampleNonVariationAttribute(name: "attr-extra", options: ["Option X", "Option Y"])
        let product = Product.fake().copy(attributes: [attribute])
        let product2 = Product.fake().copy(attributes: [attribute, attribute2, attribute3])

        // When
        let viewModel = EditAttributesViewModel(product: product, allowVariationCreation: false, featureFlagService: MockFeatureFlagService())
        viewModel.updateProduct(product2)

        // Then
        let expectedVM = ImageAndTitleAndTextTableViewCell.ViewModel(title: "attr",
                                                                     text: "Option 1, Option 2",
                                                                     numberOfLinesForTitle: 0,
                                                                     numberOfLinesForText: 0)
        let expectedVM2 = ImageAndTitleAndTextTableViewCell.ViewModel(title: "attr-2",
                                                                      text: "Option 3, Option 4",
                                                                      numberOfLinesForTitle: 0,
                                                                      numberOfLinesForText: 0)
        XCTAssertEqual(viewModel.attributes, [expectedVM, expectedVM2])
    }

    func test_product_attributes_indexes_match_attributes_viewModel_indexes() {
        // Given
        let attribute = sampleAttribute(name: "attr", options: ["Option 1", "Option 2"])
        let attribute2 = sampleAttribute(name: "attr-2", options: ["Option 3", "Option 4"])
        let attribute3 = sampleNonVariationAttribute(name: "attr-extra", options: ["Option X", "Option Y"])
        let product = Product.fake().copy(attributes: [attribute, attribute2, attribute3])

        // When
        let viewModel = EditAttributesViewModel(product: product, allowVariationCreation: false, featureFlagService: MockFeatureFlagService())

        // Then
        XCTAssertEqual(viewModel.attributes.count, 2)
        viewModel.attributes.enumerated().forEach { index, vm in
            XCTAssertEqual(vm.title, viewModel.productAttributeAtIndex(index).name)
        }
    }
}

extension EditAttributesViewModelTests {
    func test_when_feature_is_on_outside_variations_flow_then_all_attributes_are_listed_with_labels() {
        // Given
        let attribute = sampleAttribute(name: "Color", options: ["Red", "Blue"])
        let attribute2 = sampleNonVariationAttribute(name: "Material", options: ["Cotton"]).copy(visible: false)
        let product = Product.fake().copy(productTypeKey: ProductType.variable.rawValue, attributes: [attribute, attribute2])

        // When
        let viewModel = EditAttributesViewModel(product: product,
                                                allowVariationCreation: false,
                                                featureFlagService: featureFlagService(isNonVariationAttributesEnabled: true))

        // Then
        XCTAssertEqual(viewModel.attributes.map { $0.text }, ["Red, Blue\nUsed for variations", "Cotton\nHidden"])
        XCTAssertEqual(viewModel.productAttributeAtIndex(1), attribute2)
    }

    func test_when_feature_is_on_for_a_simple_product_then_no_used_for_variations_label_is_shown() {
        // Given
        let attribute = sampleAttribute(name: "Color", options: ["Red"])
        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue, attributes: [attribute])

        // When
        let viewModel = EditAttributesViewModel(product: product,
                                                allowVariationCreation: false,
                                                featureFlagService: featureFlagService(isNonVariationAttributesEnabled: true))

        // Then
        XCTAssertEqual(viewModel.attributes.map { $0.text }, ["Red"])
    }

    func test_when_feature_is_on_in_variations_flow_then_only_variation_attributes_are_listed_without_labels() {
        // Given
        let attribute = sampleAttribute(name: "Color", options: ["Red", "Blue"])
        let attribute2 = sampleNonVariationAttribute(name: "Material", options: ["Cotton"])
        let product = Product.fake().copy(productTypeKey: ProductType.variable.rawValue, attributes: [attribute, attribute2])

        // When
        let viewModel = EditAttributesViewModel(product: product,
                                                allowVariationCreation: true,
                                                featureFlagService: featureFlagService(isNonVariationAttributesEnabled: true))

        // Then
        XCTAssertEqual(viewModel.attributes.map { $0.title }, ["Color"])
        XCTAssertEqual(viewModel.attributes.map { $0.text }, ["Red, Blue"])
        XCTAssertTrue(viewModel.isVariationsFlow)
    }
}

private extension EditAttributesViewModelTests {
    func featureFlagService(isNonVariationAttributesEnabled: Bool) -> MockFeatureFlagService {
        let service = MockFeatureFlagService()
        service.isFeatureFlagEnabledReturnValue[.nonVariationProductAttributes] = isNonVariationAttributesEnabled
        return service
    }

    func sampleAttribute(attributeID: Int64 = 1234, name: String, options: [String] = []) -> ProductAttribute {
        ProductAttribute(siteID: 123,
                         attributeID: attributeID,
                         name: name,
                         position: 0,
                         visible: true,
                         variation: true,
                         options: options)
    }

    func sampleNonVariationAttribute(attributeID: Int64 = 9999, name: String, options: [String] = []) -> ProductAttribute {
        ProductAttribute(siteID: 123,
                         attributeID: attributeID,
                         name: name,
                         position: 0,
                         visible: true,
                         variation: false,
                         options: options)
    }
}
