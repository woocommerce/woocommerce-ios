@testable import WooCommerce
import XCTest

final class AddCustomAmountViewModelTests: XCTestCase {
    func test_shouldDisableDoneButton_when_amount_is_not_greater_than_zero_then_disables_done_button() {
        // Given
        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: {_, _ in })

        // When
        viewModel.formattableAmountTextFieldViewModel.amount = "$0"

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_shouldDisableDoneButton_when_there_is_no_amount_then_disables_done_button() {
        // Given
        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: {_, _ in })

        // When
        viewModel.formattableAmountTextFieldViewModel.amount = ""

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_doneButtonPressed_when_there_is_no_name_then_passes_placeholder() {
        // Given
        var passedName: String?
        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: { amount, name in
            passedName = name
        })

        // When
        viewModel.doneButtonPressed()

        // Then
        XCTAssertEqual(passedName, "Custom amount")
    }

    func test_doneButtonPressed_then_passes_amount_and_name() {
        // Given
        var passedName: String?
        var passedAmount: String?
        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: { amount, name in
            passedAmount = amount
            passedName = name
        })

        viewModel.formattableAmountTextFieldViewModel.amount = "$23"
        viewModel.name = "Custom amount name"
        
        // When
        viewModel.doneButtonPressed()

        // Then
        XCTAssertEqual(passedName, viewModel.name)
        XCTAssertEqual(passedAmount, viewModel.formattableAmountTextFieldViewModel.amount)
    }
}
