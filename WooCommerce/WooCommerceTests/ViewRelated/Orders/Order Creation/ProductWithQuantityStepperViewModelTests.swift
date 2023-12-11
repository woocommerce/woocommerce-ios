import XCTest
import Yosemite
@testable import WooCommerce

final class ProductWithQuantityStepperViewModelTests: XCTestCase {

    // MARK: - Quantity

    func test_ProductStepperViewModel_and_ProductRowViewModel_quantity_have_the_same_initial_value() {
        // When
        let viewModel = ProductWithQuantityStepperViewModel(stepperViewModel: .init(quantity: 2,
                                                                                    name: "",
                                                                                    quantityUpdatedCallback: { _ in }),
                                                            rowViewModel: .init(product: .fake()))

        // Then
        XCTAssertEqual(viewModel.stepperViewModel.quantity, 2)
        XCTAssertEqual(viewModel.rowViewModel.quantity, 2)
    }

    func test_ProductStepperViewModel_quantity_change_updates_ProductRowViewModel_quantity() {
        // Given
        let viewModel = ProductWithQuantityStepperViewModel(stepperViewModel: .init(quantity: 2,
                                                                                    name: "",
                                                                                    quantityUpdatedCallback: { _ in }),
                                                            rowViewModel: .init(product: .fake()))

        // When
        viewModel.stepperViewModel.incrementQuantity()

        // Then
        XCTAssertEqual(viewModel.stepperViewModel.quantity, 3)
        XCTAssertEqual(viewModel.rowViewModel.quantity, 3)
    }
}
