import Testing
import WooFoundation
import Yosemite
@testable import WooCommerce

@MainActor
struct SetUpTapToPayTryPaymentPromptViewModelTests {
    @Test func tryAPaymentTapped_creates_order_in_store_currency() throws {
        // Given
        let siteID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.sessionManager.setStoreId(siteID)
        let configuration = CardPresentPaymentsConfiguration(country: .US)
        let tracker = CardReaderConnectionAnalyticsTracker(configuration: configuration,
                                                           siteID: siteID,
                                                           connectionType: .userInitiated,
                                                           stores: stores)
        let currencySettings = CurrencySettings(currencyCode: .EUR,
                                                currencyPosition: .left,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)
        let sut = SetUpTapToPayTryPaymentPromptViewModel(didChangeShouldShow: nil,
                                                        connectionAnalyticsTracker: tracker,
                                                        configuration: configuration,
                                                        stores: stores,
                                                        currencySettings: currencySettings)

        // When
        sut.tryAPaymentTapped()

        // Then
        let action = try #require(stores.receivedActions.compactMap { $0 as? OrderAction }.last)
        guard case let .createSimplePaymentsOrder(receivedSiteID, _, _, _, currency, _) = action else {
            Issue.record("Expected a createSimplePaymentsOrder action")
            return
        }
        #expect(receivedSiteID == siteID)
        #expect(currency == CurrencyCode.EUR.rawValue)
    }
}
