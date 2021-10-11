import Foundation
import XCTest

@testable import WooCommerce

final class QuickPayAmountViewModelTests: XCTestCase {

    func test_view_model_prepends_currency_symbol() {
        // Given
        let viewModel = QuickPayAmountViewModel()

        // When
        viewModel.amount = "12"

        // Then
        XCTAssertEqual(viewModel.amount, "$12")
    }

    func test_view_model_removes_non_digit_characters() {
        // Given
        let viewModel = QuickPayAmountViewModel()

        // When
        viewModel.amount = "hi:11.30-"

        // Then
        XCTAssertEqual(viewModel.amount, "$11.30")
    }

    func test_view_model_trims_more_than_two_decimal_numbers() {
        // Given
        let viewModel = QuickPayAmountViewModel()

        // When
        viewModel.amount = "$67.321432432"

        // Then
        XCTAssertEqual(viewModel.amount, "$67.32")
    }

    func test_view_model_removes_duplicated_decimal_separators() {
        // Given
        let viewModel = QuickPayAmountViewModel()

        // When
        viewModel.amount = "$6.7.3"

        // Then
        XCTAssertEqual(viewModel.amount, "$6.7")
    }

    func test_view_model_removes_consecutive_decimal_separators() {
        // Given
        let viewModel = QuickPayAmountViewModel()

        // When
        viewModel.amount = "$6..."

        // Then
        XCTAssertEqual(viewModel.amount, "$6.")
    }

    func test_view_model_disables_next_button_when_there_is_no_amount() {
        // Given
        let viewModel = QuickPayAmountViewModel()

        // When
        viewModel.amount = ""

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_disables_next_button_when_amount_only_has_currency_symbol() {
        // Given
        let viewModel = QuickPayAmountViewModel()

        // When
        viewModel.amount = "$"

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_enables_next_button_when_amount_has_more_than_one_character() {
        // Given
        let viewModel = QuickPayAmountViewModel()

        // When
        viewModel.amount = "$2"

        // Then
        XCTAssertFalse(viewModel.shouldDisableDoneButton)
    }
}
