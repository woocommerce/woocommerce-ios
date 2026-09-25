import Foundation
import Testing
import WooFoundation
@testable import PointOfSale

struct POSCashSessionMoneyTests {
    @Test func test_format_when_store_currency_changes_then_preserves_session_currency_and_precision() {
        // Given
        let settings = CurrencySettings(currencyCode: .EUR, currencyPosition: .left,
                                        thousandSeparator: ",", decimalSeparator: ".", numberOfDecimals: 0)
        let session = POSCashSession(id: 1, openedAt: .now, openedBy: "Staff", openingCash: 0, movements: [],
                                     currency: "USD", currencyPrecision: 2)

        // When
        let money = POSCashSessionMoney(settings: settings, session: session)
        let result = money.format(Decimal(12345) / 100)

        // Then
        #expect(result == "$123.45")
        #expect(money.currencySettings.currencyCode == .USD)
        #expect(money.currencySettings.fractionDigits == 2)
        #expect(settings.currencyCode == .EUR)
        #expect(settings.fractionDigits == 0)
    }

    @Test func test_format_when_currency_is_unknown_then_keeps_its_code() {
        // Given
        let session = POSCashSession(id: 1, openedAt: .now, openedBy: "Staff", openingCash: 0, movements: [],
                                     currency: "XTS", currencyPrecision: 3)

        // When
        let result = POSCashSessionMoney(settings: CurrencySettings(), session: session).format(12)

        // Then
        #expect(result == "12.000 XTS")
    }
}
