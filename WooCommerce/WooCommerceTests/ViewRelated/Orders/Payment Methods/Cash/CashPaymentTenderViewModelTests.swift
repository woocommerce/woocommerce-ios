import XCTest
import Combine
import WooFoundation
@testable import WooCommerce

final class CashPaymentTenderViewModelTests: XCTestCase {
    private let usStoreSettings = CurrencySettings()
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    func test_when_amount_is_not_sufficient_it_handles_invalid_input() {
        // Given
        let viewModel = CashPaymentTenderViewModel(formattedTotal: "10.00", onOrderPaid: { _ in })

        // When
        viewModel.formattableAmountViewModel.updateAmount("5")

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
        viewModel.formattableAmountViewModel.updateAmount("1")
        viewModel.formattableAmountViewModel.updateAmount("15")

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
        viewModel.formattableAmountViewModel.updateAmount("5")
        viewModel.formattableAmountViewModel.updateAmount("5.")
        viewModel.formattableAmountViewModel.updateAmount("5.5")
        viewModel.addNote = true
        viewModel.onMarkOrderAsCompleteButtonTapped()

        // Then
        XCTAssertEqual(onOrderPaidInfo?.customerPaidAmount, "$5.50")
        XCTAssertEqual(onOrderPaidInfo?.changeGivenAmount, "$0.50")
        XCTAssertEqual(onOrderPaidInfo?.addNoteWithChangeData, true)
    }

    // MARK: Analytics

    func test_when_change_due_is_positive_and_note_is_added_it_tracks_event_with_expected_properties() throws {
        // Given
        let viewModel = CashPaymentTenderViewModel(formattedTotal: "$1.00", onOrderPaid: { _ in }, storeCurrencySettings: usStoreSettings, analytics: analytics)

        // When
        viewModel.formattableAmountViewModel.updateAmount("5")
        viewModel.addNote = true
        viewModel.onMarkOrderAsCompleteButtonTapped()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: {
            $0 == "cash_payment_tender_view_on_mark_order_as_complete_button_tapped"
        }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["change_due_was_calculated"] as? Bool, true)
        XCTAssertEqual(eventProperties["add_note"] as? Bool, true)
    }

    func test_when_change_due_is_not_calculated_and_note_is_not_added_it_tracks_event_with_expected_properties() throws {
        // Given
        let viewModel = CashPaymentTenderViewModel(formattedTotal: "$1.00", onOrderPaid: { _ in }, storeCurrencySettings: usStoreSettings, analytics: analytics)

        // When
        viewModel.onMarkOrderAsCompleteButtonTapped()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: {
            $0 == "cash_payment_tender_view_on_mark_order_as_complete_button_tapped"
        }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["change_due_was_calculated"] as? Bool, false)
        XCTAssertEqual(eventProperties["add_note"] as? Bool, false)
    }
}
