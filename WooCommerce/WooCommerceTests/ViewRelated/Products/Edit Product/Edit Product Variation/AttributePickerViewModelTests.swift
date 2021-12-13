import XCTest

@testable import WooCommerce
@testable import Yosemite


/// Tests for `AttributePickerViewModel`.
///
final class AttributePickerViewModelTests: XCTestCase {

    func test_viewmodel_saves_option_change_for_attribute() throws {
        // Given
        let attributes = [ProductVariationAttribute(id: 1, name: "Color", option: "Blue"),
                          ProductVariationAttribute(id: 0, name: "Logo", option: "Yes")]
        let variation = MockProductVariation().productVariation().copy(attributes: attributes)
        let model = EditableProductVariationModel(productVariation: variation)
        let viewModel = AttributePickerViewModel(variationModel: model)

        // When
        viewModel.update(oldAttribute: ProductVariationAttribute(id: 1, name: "Color", option: "Blue"),
                         to: ProductVariationAttribute(id: 1, name: "Color", option: "Red"))

        // Then
        XCTAssertTrue(viewModel.isChanged)
        XCTAssertEqual(viewModel.resultAttributes.count, 2)
        XCTAssertEqual(viewModel.resultAttributes.first(where: { $0.id == 1 })?.option, "Red")
    }

    func test_viewmodel_saves_option_switch_to_any() throws {
        // Given
        let attributes = [ProductVariationAttribute(id: 1, name: "Color", option: "Blue"),
                          ProductVariationAttribute(id: 0, name: "Logo", option: "Yes")]
        let variation = MockProductVariation().productVariation().copy(attributes: attributes)
        let model = EditableProductVariationModel(productVariation: variation)
        let viewModel = AttributePickerViewModel(variationModel: model)

        // When
        viewModel.update(oldAttribute: ProductVariationAttribute(id: 1, name: "Color", option: "Blue"),
                         to: nil)

        // Then
        XCTAssertTrue(viewModel.isChanged)
        XCTAssertEqual(viewModel.resultAttributes.count, 1)
        XCTAssertNil(viewModel.resultAttributes.first(where: { $0.id == 1 }))
    }

    func test_viewmodel_saves_option_switch_from_any() throws {
        // Given
        let attributes = [ProductVariationAttribute(id: 0, name: "Logo", option: "Yes")]
        let variation = MockProductVariation().productVariation().copy(attributes: attributes)
        let model = EditableProductVariationModel(productVariation: variation)
        let viewModel = AttributePickerViewModel(variationModel: model)

        // When
        viewModel.update(oldAttribute: nil,
                         to: ProductVariationAttribute(id: 1, name: "Color", option: "Blue"))

        // Then
        XCTAssertTrue(viewModel.isChanged)
        XCTAssertEqual(viewModel.resultAttributes.count, 2)
        XCTAssertEqual(viewModel.resultAttributes.first(where: { $0.id == 1 })?.option, "Blue")
    }

    func test_viewmodel_changed_state_works_correctly() throws {
        // Given
        let attributes = [ProductVariationAttribute(id: 1, name: "Color", option: "Blue"),
                          ProductVariationAttribute(id: 0, name: "Logo", option: "Yes")]
        let variation = MockProductVariation().productVariation().copy(attributes: attributes)
        let model = EditableProductVariationModel(productVariation: variation)
        let viewModel = AttributePickerViewModel(variationModel: model)

        // When
        viewModel.update(oldAttribute: ProductVariationAttribute(id: 1, name: "Color", option: "Blue"),
                         to: ProductVariationAttribute(id: 1, name: "Color", option: "Red"))

        // Then
        XCTAssertTrue(viewModel.isChanged)

        // When
        viewModel.update(oldAttribute: ProductVariationAttribute(id: 1, name: "Color", option: "Red"),
                         to: ProductVariationAttribute(id: 1, name: "Color", option: "Blue"))

        // Then
        XCTAssertFalse(viewModel.isChanged)
    }

    func test_viewmodel_changed_state_ignores_attributes_order() throws {
        // Given
        let attributes = [ProductVariationAttribute(id: 1, name: "Color", option: "Blue"),
                          ProductVariationAttribute(id: 0, name: "Logo", option: "Yes")]
        let variation = MockProductVariation().productVariation().copy(attributes: attributes)
        let model = EditableProductVariationModel(productVariation: variation)
        let viewModel = AttributePickerViewModel(variationModel: model)

        // When
        viewModel.update(oldAttribute: ProductVariationAttribute(id: 1, name: "Color", option: "Blue"),
                         to: nil)
        viewModel.update(oldAttribute: nil,
                         to: ProductVariationAttribute(id: 1, name: "Color", option: "Blue"))

        // Then
        XCTAssertFalse(viewModel.isChanged)
    }

    func test_viewmodel_changed_state_does_not_crash_on_unexpected_data() throws {
        // Given
        let attributes = [ProductVariationAttribute(id: 1, name: "Color", option: "Blue"),
                          ProductVariationAttribute(id: 0, name: "Logo", option: "Yes")]
        let variation = MockProductVariation().productVariation().copy(attributes: attributes)
        let model = EditableProductVariationModel(productVariation: variation)
        let viewModel = AttributePickerViewModel(variationModel: model)

        // When
        viewModel.update(oldAttribute: ProductVariationAttribute(id: 2, name: "Size", option: "Small"),
                         to: ProductVariationAttribute(id: 2, name: "Size", option: "Large"))

        // Then
        XCTAssertFalse(viewModel.isChanged)
    }
}
