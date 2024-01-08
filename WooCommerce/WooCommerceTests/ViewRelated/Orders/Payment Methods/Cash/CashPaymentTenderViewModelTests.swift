import XCTest
import Combine
import WooFoundation
@testable import WooCommerce

final class CashPaymentTenderViewModelTests: XCTestCase {
    private let usStoreSettings = CurrencySettings()

    func test_when_amount_is_not_sufficient_it_handles_invalid_input() {
        // Given
        let viewModel = CashPaymentTenderViewModel(formattedTotal: "10.00", onOrderPaid: { _ in })

        // When
        viewModel.formattableAmountViewModel.amount = "5"

        // Then
        XCTAssertFalse(viewModel.tenderButtonIsEnabled)
        XCTAssertFalse(viewModel.hasChangeDue)
        XCTAssertEqual(viewModel.changeDue, "-")
    }

    func test_when_amount_is_sufficient_it_handles_valid_input() {
        // Given
        let viewModel = CashPaymentTenderViewModel(formattedTotal: "$10.00", onOrderPaid: { _ in }, storeCurrencySettings: usStoreSettings)

        // When
        // Formattable input amount needs to be entered one digit at a time.
        viewModel.formattableAmountViewModel.amount = "1"
        viewModel.formattableAmountViewModel.amount = "15"

        // Then
        XCTAssertTrue(viewModel.tenderButtonIsEnabled)
        XCTAssertTrue(viewModel.hasChangeDue)
        XCTAssertEqual(viewModel.changeDue, "$5.00")
    }

    func test_when_onMarkOrderAsCompleteButtonTapped_it_calls_callback_with_right_info() {
        // Given
        var onOrderPaidInfo: OrderPaidByCashInfo?
        let viewModel = CashPaymentTenderViewModel(formattedTotal: "$5.00", onOrderPaid: { info in
            onOrderPaidInfo = info
        }, storeCurrencySettings: usStoreSettings)

        // When
        // Formattable input amount needs to be entered one digit at a time.
        viewModel.formattableAmountViewModel.amount = "5"
        viewModel.formattableAmountViewModel.amount = "5."
        viewModel.formattableAmountViewModel.amount = "5.5"
        viewModel.addNote = true
        viewModel.onMarkOrderAsCompleteButtonTapped()

        // Then
        XCTAssertEqual(onOrderPaidInfo?.customerPaidAmount, "$5.50")
        XCTAssertEqual(onOrderPaidInfo?.changeGivenAmount, "$0.50")
        XCTAssertEqual(onOrderPaidInfo?.addNoteWithChangeData, true)
    }
}
