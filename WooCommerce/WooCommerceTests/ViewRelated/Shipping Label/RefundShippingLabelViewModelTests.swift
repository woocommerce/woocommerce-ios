import XCTest
@testable import WooCommerce
import Yosemite

final class RefundShippingLabelViewModelTests: XCTestCase {
    func test_refundableAmount_is_formatted_correctly() {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(refundableAmount: 16.331134)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let viewModel = RefundShippingLabelViewModel(shippingLabel: shippingLabel, currencyFormatter: currencyFormatter)

        // When
        let refundableAmount = viewModel.refundableAmount

        // Then
        XCTAssertEqual(refundableAmount, "$16.33")
    }

    func test_refundButtonTitle_is_formatted_correctly() {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(refundableAmount: 1000.331134)
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())
        let viewModel = RefundShippingLabelViewModel(shippingLabel: shippingLabel, currencyFormatter: currencyFormatter)

        // When
        let refundButtonTitle = viewModel.refundButtonTitle

        // Then
        let expectedTitle = String.localizedStringWithFormat(RefundShippingLabelViewModel.Localization.refundButtonTitleFormat, "$1,000.33")
        XCTAssertEqual(refundButtonTitle, expectedTitle)
    }

    func test_refundShippingLabel_returns_success_result_on_success() throws {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(refundableAmount: 1000.331134)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let expectedRefund = ShippingLabelRefund(dateRequested: Date(), status: .pending)
        stores.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .refundShippingLabel(_, onCompletion):
                onCompletion(.success(expectedRefund))
            default:
                break
            }
        }
        let viewModel = RefundShippingLabelViewModel(shippingLabel: shippingLabel,
                                                     currencyFormatter: CurrencyFormatter(currencySettings: .init()),
                                                     stores: stores)

        // When
        let refundResult = waitFor { promise in
            viewModel.refundShippingLabel { result in
                promise(result)
            }
        }

        // Then
        XCTAssertEqual(try XCTUnwrap(refundResult.get()), expectedRefund)
    }

    func test_refundShippingLabel_returns_error_result_on_failure() throws {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(refundableAmount: 1000.331134)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let expectedError = RefundError.unknown
        stores.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .refundShippingLabel(_, onCompletion):
                onCompletion(.failure(expectedError))
            default:
                break
            }
        }
        let viewModel = RefundShippingLabelViewModel(shippingLabel: shippingLabel,
                                                     currencyFormatter: CurrencyFormatter(currencySettings: .init()),
                                                     stores: stores)

        // When
        let refundResult = waitFor { promise in
            viewModel.refundShippingLabel { result in
                promise(result)
            }
        }

        // Then
        XCTAssertEqual(try XCTUnwrap(refundResult.failure) as? RefundError, expectedError)
    }

    func test_refundShippingLabel_logs_analytics() throws {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(refundableAmount: 1000.331134)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = RefundShippingLabelViewModel(shippingLabel: shippingLabel,
                                                     currencyFormatter: CurrencyFormatter(currencySettings: .init()),
                                                     stores: stores,
                                                     analytics: analytics)

        // When
        viewModel.refundShippingLabel { _ in }

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)
        XCTAssertEqual(analyticsProvider.receivedEvents.first, "shipping_label_refund_requested")
    }
}

private extension RefundShippingLabelViewModelTests {
    enum RefundError: Error, Equatable {
        case unknown
    }
}
