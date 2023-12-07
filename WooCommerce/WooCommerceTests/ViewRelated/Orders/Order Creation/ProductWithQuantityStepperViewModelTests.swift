import XCTest
import Yosemite
@testable import WooCommerce

final class ProductWithQuantityStepperViewModelTests: XCTestCase {

    // MARK: - `isReadOnly`

    func test_isReadOnly_is_false_for_products_by_default() {
        // Given
        let product = Product.fake()

        // When
        let viewModel = ProductWithQuantityStepperViewModel(stepperViewModel: .init(quantity: 1,
                                                                                    name: "",
                                                                                    quantityUpdatedCallback: { _ in }),
                                                            rowViewModel: .init(product: product),
                                                            canChangeQuantity: true)

        // Then
        XCTAssertFalse(viewModel.isReadOnly, "Product should not be read only")
    }

    func test_isReadOnly_is_false_for_non_bundle_parent_and_child_items() throws {
        // Given
        let parent = Product.fake()
        let children = [ProductRowViewModel(product: .fake()),
                        ProductRowViewModel(productVariation: .fake(), name: "Variation", displayMode: .stock)]
            .map {
                ProductWithQuantityStepperViewModel(stepperViewModel: .init(quantity: 1,
                                                                            name: "",
                                                                            quantityUpdatedCallback: { _ in }),
                                                    rowViewModel: $0,
                                                    canChangeQuantity: true)
            }

        // When
        let viewModel = ProductWithQuantityStepperViewModel(stepperViewModel: .init(quantity: 1,
                                                                                    name: "",
                                                                                    quantityUpdatedCallback: { _ in }),
                                                            rowViewModel: .init(product: parent),
                                                            canChangeQuantity: false,
                                                            childProductRows: children)

        // Then
        XCTAssertFalse(viewModel.isReadOnly, "Parent product should not be read only")
        XCTAssertFalse(try XCTUnwrap(viewModel.childProductRows[0]).isReadOnly, "Child product should not be read only")
        XCTAssertFalse(try XCTUnwrap(viewModel.childProductRows[1]).isReadOnly, "Child product variation should not be read only")
    }

    // MARK: - Quantity

    func test_ProductStepperViewModel_and_ProductRowViewModel_quantity_have_the_same_initial_value() {
        // When
        let viewModel = ProductWithQuantityStepperViewModel(stepperViewModel: .init(quantity: 2,
                                                                                    name: "",
                                                                                    quantityUpdatedCallback: { _ in }),
                                                            rowViewModel: .init(product: .fake()),
                                                            canChangeQuantity: true)

        // Then
        XCTAssertEqual(viewModel.stepperViewModel.quantity, 2)
        XCTAssertEqual(viewModel.rowViewModel.quantity, 2)
    }

    func test_ProductStepperViewModel_quantity_change_updates_ProductRowViewModel_quantity() {
        // Given
        let viewModel = ProductWithQuantityStepperViewModel(stepperViewModel: .init(quantity: 2,
                                                                                    name: "",
                                                                                    quantityUpdatedCallback: { _ in }),
                                                            rowViewModel: .init(product: .fake()),
                                                            canChangeQuantity: true)

        // When
        viewModel.stepperViewModel.incrementQuantity()

        // Then
        XCTAssertEqual(viewModel.stepperViewModel.quantity, 3)
        XCTAssertEqual(viewModel.rowViewModel.quantity, 3)
    }
}
