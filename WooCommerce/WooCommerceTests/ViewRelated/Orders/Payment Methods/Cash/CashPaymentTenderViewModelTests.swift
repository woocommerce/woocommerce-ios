import XCTest
import Combine
import WooFoundation
@testable import WooCommerce

class CashPaymentTenderViewModelTests: XCTestCase {
    func test_customerCash_when_amount_is_not_suficient_handles_invalid_input() {
        let viewModel = CashPaymentTenderViewModel(formattedTotal: "10.00", onOrderPaid: {})
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
        let viewModel = CashPaymentTenderViewModel(formattedTotal: "10.00", onOrderPaid: {}, storeCurrencySettings: usStoreSettings)
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

    func test_onTenderButtonTapped_then_calls_callback() {
        // Given
        var onOrderPaidCalled = false
        let viewModel = CashPaymentTenderViewModel(formattedTotal: "10.00", onOrderPaid: {
            onOrderPaidCalled = true
        })

        // When
        viewModel.onTenderButtonTapped()

        // Then
        XCTAssertTrue(onOrderPaidCalled)
    }
}
