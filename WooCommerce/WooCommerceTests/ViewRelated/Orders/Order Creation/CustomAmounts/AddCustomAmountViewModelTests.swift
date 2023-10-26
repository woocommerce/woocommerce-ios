@testable import WooCommerce
@testable import Yosemite
import XCTest
import Fakes

final class AddCustomAmountViewModelTests: XCTestCase {
    func test_shouldDisableDoneButton_when_amount_is_not_greater_than_zero_then_disables_done_button() {
        // Given
        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: {_, _, _ in })

        // When
        viewModel.formattableAmountTextFieldViewModel.amount = "$0"

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_shouldDisableDoneButton_when_there_is_no_amount_then_disables_done_button() {
        // Given
        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: {_, _, _ in })

        // When
        viewModel.formattableAmountTextFieldViewModel.amount = ""

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_doneButtonPressed_when_there_is_no_name_then_passes_placeholder() {
        // Given
        var passedName: String?
        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: { amount, name, _ in
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

        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: { amount, name, _ in
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

    func test_doneButtonPressed_when_a_fee_is_preset_then_passes_its_data() {
        // Given
        let amount = "23"
        let name = "Custom amount name"
        let feeID: Int64 = 12345

        var passedName: String?
        var passedAmount: String?
        var passedFeeID: Int64?

        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: { amount, name, feeID in
            passedAmount = amount
            passedName = name
            passedFeeID = feeID
        })

        viewModel.preset(with: OrderFeeLine.fake().copy(feeID: feeID, name: name, total: amount))

        // When
        viewModel.doneButtonPressed()

        // Then
        XCTAssertEqual(passedName, name)
        XCTAssertEqual(passedAmount, amount)
        XCTAssertEqual(passedFeeID, feeID)
    }

    func test_reset_then_reset_values() {
        // Given
        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: {_, _, _ in })
        viewModel.formattableAmountTextFieldViewModel.amount = "2"
        viewModel.name = "test"
        viewModel.feeID = 12345

        // When
        viewModel.reset()

        // Then
        XCTAssertTrue(viewModel.formattableAmountTextFieldViewModel.amount.isEmpty)
        XCTAssertTrue(viewModel.name.isEmpty)
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
        XCTAssertNil(viewModel.feeID)
    }

    func test_doneButtonPressed_when_name_is_empty_then_it_tracks_only_done_event() {
        // Given
        let analytics = MockAnalyticsProvider()

        // When
        let viewModel = AddCustomAmountViewModel(analytics: WooAnalytics(analyticsProvider: analytics), onCustomAmountEntered: {_, _, _ in })
        viewModel.name = ""
        viewModel.doneButtonPressed()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.addCustomAmountDoneButtonTapped.rawValue)
        XCTAssertEqual(analytics.receivedEvents.count, 1)
    }

    func test_doneButtonPressed_when_name_is_not_empty_then_it_tracks_name_event() {
        // Given
        let analytics = MockAnalyticsProvider()

        // When
        let viewModel = AddCustomAmountViewModel(analytics: WooAnalytics(analyticsProvider: analytics), onCustomAmountEntered: {_, _, _ in })
        viewModel.name = "test"
        viewModel.doneButtonPressed()

        // Then
        XCTAssertNotNil(analytics.receivedEvents.first(where: { $0 == WooAnalyticsStat.addCustomAmountNameAdded.rawValue }))
    }
}
