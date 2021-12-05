import Foundation
import XCTest
import Combine

@testable import WooCommerce
@testable import Yosemite

final class SimplePaymentsSummaryViewModelTests: XCTestCase {

    var subscriptions = Set<AnyCancellable>()

    func test_updating_noteViewModel_updates_noteContent_property() {
        // Given
        let viewModel = SimplePaymentsSummaryViewModel(providedAmount: "$100.00", totalWithTaxes: "$104.30", taxAmount: "$4.3")

        // When
        viewModel.noteViewModel.newNote = "Updated note"

        // Then
        assertEqual(viewModel.noteContent, viewModel.noteViewModel.newNote)
    }

    func test_calling_reloadContent_triggers_viewModel_update() {
        // Given
        let viewModel = SimplePaymentsSummaryViewModel(providedAmount: "$100.00", totalWithTaxes: "$104.30", taxAmount: "$4.3")

        // When
        let triggeredUpdate: Bool = waitFor { promise in
            viewModel.objectWillChange.sink {
                promise(true)
            }
            .store(in: &self.subscriptions)

            viewModel.reloadContent()
        }

        // Then
        XCTAssertTrue(triggeredUpdate)
    }

    func test_provided_amount_gets_properly_formatted() {
        // Given
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Default is US.
        let viewModel = SimplePaymentsSummaryViewModel(providedAmount: "100", totalWithTaxes: "104.30", taxAmount: "$4.3", currencyFormatter: currencyFormatter)

        // When & Then
        XCTAssertEqual(viewModel.providedAmount, "$100.00")
        XCTAssertEqual(viewModel.total, "$100.00")
    }

    func test_provided_amount_with_taxes_gets_properly_formatted() {
        // Given
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Default is US.
        let viewModel = SimplePaymentsSummaryViewModel(providedAmount: "100", totalWithTaxes: "104.30", taxAmount: "$4.3", currencyFormatter: currencyFormatter)

        // When
        viewModel.enableTaxes = true

        // Then
        XCTAssertEqual(viewModel.providedAmount, "$100.00")
        XCTAssertEqual(viewModel.total, "$104.30")
    }

    func test_tax_amount_is_properly_formatted() {
        // Given
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Default is US.
        let viewModel = SimplePaymentsSummaryViewModel(providedAmount: "100", totalWithTaxes: "104.30", taxAmount: "4.3", currencyFormatter: currencyFormatter)

        // When & Then
        XCTAssertEqual(viewModel.taxAmount, "$4.30")
    }

    func test_tax_rate_is_calculated_properly() {
        // Given
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Default is US.
        let viewModel = SimplePaymentsSummaryViewModel(providedAmount: "100", totalWithTaxes: "104.30", taxAmount: "$4.3", currencyFormatter: currencyFormatter)

        // When & Then
        XCTAssertEqual(viewModel.taxRate, "4.30")
    }

    func test_when_order_is_updated_loading_indicator_is_toggled() {
        // Given
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = SimplePaymentsSummaryViewModel(providedAmount: "1.0", totalWithTaxes: "1.0", taxAmount: "0.0", stores: mockStores)
        mockStores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateSimplePaymentsOrder(_, _, _, _, _, _, _, onCompletion):
                onCompletion(.success(Order.fake()))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let loadingStates: [Bool] = waitFor { promise in
            viewModel.$showLoadingIndicator
                .dropFirst() // Initial value
                .collect(2)  // Collect toggle
                .first()
                .sink { loadingStates in
                    promise(loadingStates)
                }
                .store(in: &self.subscriptions)
            viewModel.updateOrder()
        }

        // Then
        XCTAssertEqual(loadingStates, [true, false]) // Loading, then not loading.
    }

    func test_view_model_attempts_error_notice_presentation_when_failing_to_update_order() {
        // Given
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let noticeSubject = PassthroughSubject<SimplePaymentsNotice, Never>()
        let viewModel = SimplePaymentsSummaryViewModel(providedAmount: "1.0",
                                                       totalWithTaxes: "1.0",
                                                       taxAmount: "0.0",
                                                       presentNoticeSubject: noticeSubject,
                                                       stores: mockStores)
        mockStores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateSimplePaymentsOrder(_, _, _, _, _, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "Error", code: 0)))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        let receivedError: Bool = waitFor { promise in
            noticeSubject.sink { intent in
                switch intent {
                case .error:
                    promise(true)
                case .completed:
                    promise(false)
                }
            }
            .store(in: &self.subscriptions)
            viewModel.updateOrder()
        }

        // Then
        XCTAssertTrue(receivedError)
    }

    func test_when_order_is_updated_navigation_to_payments_method_is_triggered() {
        // Given
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = SimplePaymentsSummaryViewModel(providedAmount: "1.0", totalWithTaxes: "1.0", taxAmount: "0.0", stores: mockStores)
        mockStores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateSimplePaymentsOrder(_, _, _, _, _, _, _, onCompletion):
                onCompletion(.success(Order.fake()))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        XCTAssertFalse(viewModel.navigateToPaymentMethods)

        // When
        viewModel.updateOrder()

        // Then
        XCTAssertTrue(viewModel.navigateToPaymentMethods)
    }
}
