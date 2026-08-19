import PointOfSale
import Testing
@testable import WooCommerce

struct CardPresentPaymentsTransactionAlertsProviderTests {
    @Test func test_paymentCancellationConfirmation_confirmationDisabled_returnsNil() {
        // Given
        let provider = CardPresentPaymentsTransactionAlertsProvider()

        // When
        let confirmation = provider.paymentCancellationConfirmation(onDismiss: {})

        // Then
        #expect(confirmation == nil)
    }

    @Test func test_paymentCancellationConfirmation_confirmationEnabled_returnsConfirmationWithDismissAction() {
        // Given
        let provider = CardPresentPaymentsTransactionAlertsProvider(showsTapToPayCancellationConfirmation: true)
        var didDismiss = false

        // When
        let confirmation = provider.paymentCancellationConfirmation {
            didDismiss = true
        }

        // Then
        guard case .paymentCancellationConfirmation(let onDismiss) = confirmation else {
            Issue.record("Expected a payment cancellation confirmation")
            return
        }
        onDismiss()
        #expect(didDismiss)
    }
}
