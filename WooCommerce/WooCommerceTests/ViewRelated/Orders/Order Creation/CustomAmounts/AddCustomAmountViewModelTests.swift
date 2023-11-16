@testable import WooCommerce
@testable import Yosemite
import XCTest
import Fakes

final class AddCustomAmountViewModelTests: XCTestCase {
    func test_shouldDisableDoneButton_when_amount_is_not_greater_than_zero_then_disables_done_button() {
        // Given
        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: {_, _, _, _ in })

        // When
        viewModel.formattableAmountTextFieldViewModel.amount = "$0"

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_shouldDisableDoneButton_when_there_is_no_amount_then_disables_done_button() {
        // Given
        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: {_, _, _, _ in })

        // When
        viewModel.formattableAmountTextFieldViewModel.amount = ""

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_doneButtonPressed_when_there_is_no_name_then_passes_placeholder() {
        // Given
        var passedName: String?
        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: { amount, name, _, _ in
            passedName = name
        })

        // When
        viewModel.doneButtonPressed()

        // Then
        XCTAssertEqual(passedName, "Custom amount")
    }

    func test_doneButtonPressed_then_isTaxable_is_true_by_default() {
        // Given
        var passedIsTaxable: Bool?
        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: { _, _, _, isTaxable in
            passedIsTaxable = isTaxable
        })

        // When
        viewModel.doneButtonPressed()

        // Then
        XCTAssertTrue(passedIsTaxable ?? false)
    }

    func test_doneButtonPressed_then_passes_amount_name_and_taxability() {
        // Given
        let amount = "23"
        let name = "Custom amount name"
        let isTaxable = false

        var passedName: String?
        var passedAmount: String?
        var passedIsTaxable: Bool?

        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: { amount, name, _, isTaxable in
            passedAmount = amount
            passedName = name
            passedIsTaxable = isTaxable
        })

        viewModel.formattableAmountTextFieldViewModel.amount = amount
        viewModel.name = name
        viewModel.isTaxable = isTaxable

        // When
        viewModel.doneButtonPressed()

        // Then
        XCTAssertEqual(passedName, name)
        XCTAssertEqual(passedAmount, amount)
        XCTAssertEqual(passedIsTaxable, isTaxable)
    }

    func test_doneButtonPressed_when_a_fee_is_preset_then_passes_its_data() {
        // Given
        let amount = "23"
        let name = "Custom amount name"
        let feeID: Int64 = 12345

        var passedName: String?
        var passedAmount: String?
        var passedFeeID: Int64?

        let viewModel = AddCustomAmountViewModel(onCustomAmountEntered: { amount, name, feeID, _ in
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

    func test_doneButtonPressed_when_name_is_empty_then_it_tracks_only_done_event() {
        // Given
        let analytics = MockAnalyticsProvider()

        // When
        let viewModel = AddCustomAmountViewModel(analytics: WooAnalytics(analyticsProvider: analytics), onCustomAmountEntered: {_, _, _, _ in })
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
        let viewModel = AddCustomAmountViewModel(analytics: WooAnalytics(analyticsProvider: analytics), onCustomAmountEntered: {_, _, _, _ in })
        viewModel.name = "test"
        viewModel.doneButtonPressed()

        // Then
        XCTAssertNotNil(analytics.receivedEvents.first(where: { $0 == WooAnalyticsStat.addCustomAmountNameAdded.rawValue }))
    }

    func test_shouldShowPercentageInput_when_baseAmountForPercentage_is_zero_then_returns_false() {
        // When
        let viewModel = AddCustomAmountViewModel(baseAmountForPercentage: 0, onCustomAmountEntered: {_, _, _, _ in })

        // Then
        XCTAssertFalse(viewModel.shouldShowPercentageInput)
    }

    func test_shouldShowPercentageInput_when_baseAmountForPercentage_is_bigger_than_zero_then_returns_true() {
        // When
        let viewModel = AddCustomAmountViewModel(baseAmountForPercentage: 1, onCustomAmountEntered: {_, _, _, _ in })

        // Then
        XCTAssertTrue(viewModel.shouldShowPercentageInput)
    }

    func test_shouldShowPercentageInput_when_baseAmountForPercentage_is_negative_then_returns_false() {
        // When
        let viewModel = AddCustomAmountViewModel(baseAmountForPercentage: -1, onCustomAmountEntered: {_, _, _ in })

        // Then
        XCTAssertFalse(viewModel.shouldShowPercentageInput)
    }

    func test_percentage_then_updates_amount() {
        // Given
        let baseAmountForPercentage = 200
        let percentage = 25

        // When
        let viewModel = AddCustomAmountViewModel(baseAmountForPercentage: Decimal(baseAmountForPercentage),
                                                 onCustomAmountEntered: {_, _, _, _ in })
        viewModel.percentage = "\(percentage)"

        // Then
        XCTAssertEqual(viewModel.formattableAmountTextFieldViewModel.amount, "\(baseAmountForPercentage / 100 * percentage)")
    }
}
