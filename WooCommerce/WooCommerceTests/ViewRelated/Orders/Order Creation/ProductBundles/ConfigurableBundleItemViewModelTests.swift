import XCTest
import Yosemite
@testable import WooCommerce

final class ConfigurableBundleItemViewModelTests: XCTestCase {
    // MARK: - Quantity from initialization

    func test_init_without_existing_order_item_sets_quantity_to_bundle_defaultQuantity() throws {
        // When
        let viewModel = ConfigurableBundleItemViewModel(bundleItem: .fake().copy(defaultQuantity: 2),
                                                        product: .fake(),
                                                        variableProductSettings: nil,
                                                        existingParentOrderItem: .fake(),
                                                        existingOrderItem: nil)

        // Then
        XCTAssertEqual(viewModel.quantity, 2)
    }

    func test_init_with_existing_order_item_and_parent_order_item_with_quantity_3_sets_quantity_divided_by_3() throws {
        // Given
        let existingOrderItem = OrderItem.fake().copy(productID: 6, quantity: 24)
        let existingParentOrderItem = OrderItem.fake().copy(productID: 1, quantity: 3)
        let product = Product.fake().copy()

        // When
        let viewModel = ConfigurableBundleItemViewModel(bundleItem: .fake(),
                                                        product: .fake(),
                                                        variableProductSettings: nil,
                                                        existingParentOrderItem: existingParentOrderItem,
                                                        existingOrderItem: existingOrderItem)

        // Then
        XCTAssertEqual(viewModel.quantity, 8)
    }

    func test_init_with_existing_order_item_and_parent_order_item_with_quantity_0_sets_quantity_divided_by_1() throws {
        // Given
        let existingOrderItem = OrderItem.fake().copy(productID: 6, quantity: 24)
        let existingParentOrderItem = OrderItem.fake().copy(productID: 1, quantity: 0)
        let product = Product.fake().copy()

        // When
        let viewModel = ConfigurableBundleItemViewModel(bundleItem: .fake(),
                                                        product: .fake(),
                                                        variableProductSettings: nil,
                                                        existingParentOrderItem: existingParentOrderItem,
                                                        existingOrderItem: existingOrderItem)

        // Then
        XCTAssertEqual(viewModel.quantity, 24)
    }

    func test_init_with_existing_order_item_with_full_attributes_sets_selectedVariation_and_empty_selectableVariationAttributeViewModels() throws {
        // Given
        let existingOrderItem = OrderItem.fake().copy(variationID: 6,
                                                      attributes: [
            .init(metaID: 0, name: "Color", value: "Indigo"),
            .init(metaID: 0, name: "Flavor", value: "Pineapple")
        ])
        let variableProduct = createVariableProduct()
            .copy(attributes: [
                .fake().copy(name: "Flavor", variation: true, options: ["Pineapple", "Blackberry"]),
                .fake().copy(name: "Color", variation: true, options: ["Indigo", "Orange"]),
                // Non-variation attribute.
                .fake().copy(name: "Fabric", variation: false, options: ["Cotton"])
            ])

        // When
        let viewModel = ConfigurableBundleItemViewModel(bundleItem: .fake(),
                                                        product: variableProduct,
                                                        variableProductSettings: .init(allowedVariations: [], defaultAttributes: []),
                                                        existingParentOrderItem: nil,
                                                        existingOrderItem: existingOrderItem)

        // Then
        XCTAssertEqual(viewModel.selectedVariation, .init(variationID: 6, attributes: [
            .init(id: 0, name: "Color", option: "Indigo"),
            .init(id: 0, name: "Flavor", option: "Pineapple")
        ]))
        XCTAssertEqual(viewModel.selectableVariationAttributeViewModels.count, 0)
    }

    func test_init_without_existing_order_item_sets_nil_selectedVariation_and_empty_selectableVariationAttributeViewModels() throws {
        // Given
        let variableProduct = createVariableProduct()
            .copy(attributes: [
                .fake().copy(name: "Flavor", variation: true, options: ["Pineapple", "Blackberry"])
            ])

        // When
        let viewModel = ConfigurableBundleItemViewModel(bundleItem: .fake(),
                                                        product: variableProduct,
                                                        variableProductSettings: .init(allowedVariations: [], defaultAttributes: []),
                                                        existingParentOrderItem: nil,
                                                        existingOrderItem: nil)

        // Then
        XCTAssertNil(viewModel.selectedVariation)
        XCTAssertEqual(viewModel.selectableVariationAttributeViewModels.count, 0)
    }

    func test_selecting_variation_sets_selectedVariation_and_selectableVariationAttributeViewModels() throws {
        // Given
        let variableProduct = createVariableProduct()
            .copy(attributes: [
                .fake().copy(name: "Flavor", variation: true, options: ["Pineapple", "Blackberry"]),
                .fake().copy(name: "Color", variation: true, options: ["Indigo", "Orange"]),
                // Non-variation attribute.
                .fake().copy(name: "Fabric", variation: false, options: ["Cotton"])
            ])

        // When
        let viewModel = ConfigurableBundleItemViewModel(bundleItem: .fake(),
                                                        product: variableProduct,
                                                        variableProductSettings: .init(allowedVariations: [], defaultAttributes: []),
                                                        existingParentOrderItem: nil,
                                                        existingOrderItem: nil)
        viewModel.createVariationSelectorViewModel()
        viewModel.variationSelectorViewModel?.onVariationSelectionStateChanged?(
            // Selected variation.
            .fake().copy(productVariationID: 7,
                         attributes: [
                            .init(id: 0, name: "Color", option: "Orange")
                         ]),
            // Selected product.
            .fake()
        )

        // Then
        XCTAssertEqual(viewModel.selectedVariation, .init(variationID: 7, attributes: [
            .init(id: 0, name: "Color", option: "Orange")
        ]))
        XCTAssertEqual(viewModel.selectableVariationAttributeViewModels, [
            .init(attribute: .fake().copy(name: "Flavor", variation: true, options: ["Pineapple", "Blackberry"]),
                  selectedOption: nil)
        ])
    }

    func test_selecting_variation_sets_selectedVariation_and_selectableVariationAttributeViewModels_with_default_option() throws {
        // Given
        let variableProduct = createVariableProduct()
            .copy(attributes: [
                .fake().copy(name: "Flavor", variation: true, options: ["Pineapple", "Blackberry"])
            ])

        // When
        let viewModel = ConfigurableBundleItemViewModel(bundleItem: .fake(),
                                                        product: variableProduct,
                                                        variableProductSettings: .init(allowedVariations: [], defaultAttributes: [
                                                            .init(id: 0, name: "Flavor", option: "Blackberry")
                                                        ]),
                                                        existingParentOrderItem: nil,
                                                        existingOrderItem: nil)
        viewModel.createVariationSelectorViewModel()
        viewModel.variationSelectorViewModel?.onVariationSelectionStateChanged?(
            // Selected variation.
            .fake().copy(productVariationID: 7,
                         attributes: []),
            // Selected product.
            .fake()
        )

        // Then
        XCTAssertEqual(viewModel.selectedVariation, .init(variationID: 7, attributes: []))
        XCTAssertEqual(viewModel.selectableVariationAttributeViewModels, [
            .init(attribute: .fake().copy(name: "Flavor", variation: true, options: ["Pineapple", "Blackberry"]),
                  selectedOption: "Blackberry")
        ])
    }
}

private extension ConfigurableBundleItemViewModelTests {
    func createVariableProduct() -> Product {
        Product.fake().copy(productTypeKey: ProductType.variable.rawValue)
    }
}

extension ConfigurableVariableBundleAttributePickerViewModel: Equatable {
    public static func == (lhs: ConfigurableVariableBundleAttributePickerViewModel, rhs: ConfigurableVariableBundleAttributePickerViewModel) -> Bool {
        lhs.name == rhs.name &&
        lhs.options == rhs.options &&
        lhs.selectedOption == rhs.selectedOption
    }
}
