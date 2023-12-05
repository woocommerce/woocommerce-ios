import XCTest
import Combine
import WooFoundation
@testable import WooCommerce

class CashPaymentTenderViewModelTests: XCTestCase {
    func test_customerCash_when_amount_is_not_suficient_handles_invalid_input() {
        let viewModel = CashPaymentTenderViewModel(formattedTotal: "10.00", onOrderPaid: {_ in })
        viewModel.customerCash = "5.00"

        XCTAssertFalse(viewModel.tenderButtonIsEnabled)
        XCTAssertEqual(viewModel.dueChange, "-")
    }

    func test_customerCash_when_amount_is_sufficient_handles_valid_input() {
        // Given
        let total = "$10.00"
        let customerCash = "15.00"
        let usStoreSettings = CurrencySettings()
        let currencyFormatter = CurrencyFormatter(currencySettings: usStoreSettings)

        // When
        let viewModel = CashPaymentTenderViewModel(formattedTotal: "10.00", onOrderPaid: {_ in }, storeCurrencySettings: usStoreSettings)
        viewModel.customerCash = "15.00"

        // Then
        guard let totalAmount = currencyFormatter.convertToDecimal(total) as? Decimal,
              let customerPaidAmount = currencyFormatter.convertToDecimal(customerCash) as? Decimal else {
            XCTFail()

            return
        }

        XCTAssertTrue(viewModel.tenderButtonIsEnabled)
        XCTAssertEqual(viewModel.dueChange, currencyFormatter.formatAmount(customerPaidAmount - totalAmount))
    }

    func test_onTenderButtonTapped_then_calls_callback_with_right_info() {
        // Given
        var onOrderPaidInfo: OrderPaidByCashInfo?
        let usStoreSettings = CurrencySettings()
        let currencyFormatter = CurrencyFormatter(currencySettings: usStoreSettings)
        let viewModel = CashPaymentTenderViewModel(formattedTotal: "10.00", onOrderPaid: { info in
            onOrderPaidInfo = info
        }, storeCurrencySettings: usStoreSettings)

        // When
        viewModel.customerCash = "15.00"
        viewModel.addNote = false
        viewModel.onTenderButtonTapped()

        // Then
        XCTAssertEqual(onOrderPaidInfo?.customerPaidAmount, currencyFormatter.formatHumanReadableAmount(viewModel.customerCash))
        XCTAssertEqual(onOrderPaidInfo?.changeGivenAmount, viewModel.dueChange)
        XCTAssertEqual(onOrderPaidInfo?.addNoteWithChangeData, viewModel.addNote)
    }
}
