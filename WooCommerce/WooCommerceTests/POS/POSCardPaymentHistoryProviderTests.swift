import Testing
import Yosemite
@testable import WooCommerce

@MainActor
struct POSCardPaymentHistoryProviderTests {
    @Test(arguments: [true, false])
    func hasRecordedCardPayment_returns_the_stored_value_for_the_site(hasRecordedPayment: Bool) async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var requestedSiteID: Int64?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case let .loadSiteHasAtLeastOneIPPTransactionFinished(siteID, onCompletion) = action {
                requestedSiteID = siteID
                onCompletion(hasRecordedPayment)
            }
        }
        let sut = POSCardPaymentHistoryProvider(stores: stores)

        // When
        let result = await sut.hasRecordedCardPayment(siteID: 123)

        // Then
        #expect(result == hasRecordedPayment)
        #expect(requestedSiteID == 123)
    }
}
