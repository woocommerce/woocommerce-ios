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
        let amount = "23"
        let name = "Custom amount name"

        var passedName: String?
        var passedAmount: String?

        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: { amount, name in
            passedAmount = amount
            passedName = name
        })

        viewModel.formattableAmountTextFieldViewModel.amount = amount
        viewModel.name = name

        // When
        viewModel.doneButtonPressed()

        // Then
        XCTAssertEqual(passedName, name)
        XCTAssertEqual(passedAmount, amount)
    }

    func test_reset_then_reset_values() {
        // Given
        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: {_, _ in })
        viewModel.formattableAmountTextFieldViewModel.amount = "2"
        viewModel.name = "test"

        // When
        viewModel.reset()

        // Then
        XCTAssertTrue(viewModel.formattableAmountTextFieldViewModel.amount.isEmpty)
        XCTAssertTrue(viewModel.name.isEmpty)
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }
}
