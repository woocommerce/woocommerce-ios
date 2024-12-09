import Testing

@testable import WooCommerce
import WooFoundation

struct OrderCustomAmountsSectionViewModelTests {
    @Test
    func when_created_with_usd_currencySettings_currencySymbol_returns_dollar() throws {
        // Given
        let usdSettings = CurrencySettings(currencyCode: .USD, currencyPosition: .left, thousandSeparator: "", decimalSeparator: "", numberOfDecimals: 2)
        let sut = OrderCustomAmountsSectionViewModel(currencySettings: usdSettings)
        // When, Then
        #expect(sut.currencySymbol == "$")
    }

    @Test
    func when_created_with_gbp_currencySettings_currencySymbol_returns_pound() throws {
        // Given
        let gbpSettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: "", numberOfDecimals: 2)
        let sut = OrderCustomAmountsSectionViewModel(currencySettings: gbpSettings)
        // When, Then
        #expect(sut.currencySymbol == "£")
    }
}
