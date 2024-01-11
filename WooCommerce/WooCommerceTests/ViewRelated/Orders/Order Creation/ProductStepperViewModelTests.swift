import XCTest
@testable import WooCommerce

final class ProductStepperViewModelTests: XCTestCase {
    func test_increment_and_decrement_quantity_have_step_value_of_one() {
        // Given
        let viewModel = ProductStepperViewModel(quantity: 1, name: "", minimumQuantity: 1, maximumQuantity: nil, quantityUpdatedCallback: { _ in })

        // When & Then
        viewModel.incrementQuantity()
        XCTAssertEqual(viewModel.quantity, 2)

        // When & Then
        viewModel.decrementQuantity()
        XCTAssertEqual(viewModel.quantity, 1)
    }

    func test_quantity_has_minimum_value_of_one() {
        // Given
        let viewModel = ProductStepperViewModel(quantity: 1, name: "", minimumQuantity: 1, maximumQuantity: nil, quantityUpdatedCallback: { _ in })
        XCTAssertEqual(viewModel.quantity, 1)

        // When
        viewModel.decrementQuantity()

        // Then
        XCTAssertEqual(viewModel.quantity, 1)
    }

    func test_cannot_decrement_quantity_below_zero() {
        // Given
        let viewModel = ProductStepperViewModel(quantity: 0, name: "", minimumQuantity: 0, maximumQuantity: nil, quantityUpdatedCallback: { _ in })
        XCTAssertEqual(viewModel.quantity, 0)

        // When
        viewModel.decrementQuantity()

        // Then
        XCTAssertEqual(viewModel.quantity, 0)
        XCTAssertTrue(viewModel.shouldDisableQuantityDecrementer, "Quantity decrementer is not disabled")
    }

    func test_cannot_decrement_quantity_below_minimumQuantity() {
        // Given
        let viewModel = ProductStepperViewModel(quantity: 3,
                                                name: "",
                                                minimumQuantity: 3,
                                                maximumQuantity: nil,
                                                quantityUpdatedCallback: { _ in },
                                                removeProductIntent: {})
        XCTAssertEqual(viewModel.quantity, 3)

        // When
        viewModel.decrementQuantity()

        // Then
        XCTAssertEqual(viewModel.quantity, 3)
    }

    func test_cannot_increment_quantity_beyond_maximumQuantity() {
        // Given
        let viewModel = ProductStepperViewModel(quantity: 6,
                                                name: "",
                                                minimumQuantity: 4,
                                                maximumQuantity: 6,
                                                quantityUpdatedCallback: { _ in })
        XCTAssertEqual(viewModel.quantity, 6)

        // When
        viewModel.incrementQuantity()

        // Then
        XCTAssertEqual(viewModel.quantity, 6)
    }

    func test_quantity_decrementer_disabled_at_minimum_quantity() {
        // Given
        let viewModel = ProductStepperViewModel(quantity: 3,
                                                name: "",
                                                minimumQuantity: 3,
                                                maximumQuantity: nil,
                                                quantityUpdatedCallback: { _ in },
                                                removeProductIntent: {})

        // Then
        XCTAssertTrue(viewModel.shouldDisableQuantityDecrementer)
    }

    func test_quantity_incrementer_disabled_at_maximum_quantity() {
        // Given
        let viewModel = ProductStepperViewModel(quantity: 6,
                                                name: "",
                                                minimumQuantity: 4,
                                                maximumQuantity: 6,
                                                quantityUpdatedCallback: { _ in })

        // Then
        XCTAssertTrue(viewModel.shouldDisableQuantityIncrementer)
    }
}
