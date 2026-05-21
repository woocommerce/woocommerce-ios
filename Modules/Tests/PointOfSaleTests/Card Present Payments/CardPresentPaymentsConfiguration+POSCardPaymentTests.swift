import Testing
import enum WooFoundation.CountryCode
import struct Yosemite.CardPresentPaymentsConfiguration
@testable import PointOfSale

@Suite("CardPresentPaymentsConfiguration+POSCardPayment")
struct CardPresentPaymentsConfigurationPOSCardPaymentTests {
    @Test(arguments: [
        CountryCode.US,
        .GB,
        .PR,
        .FR,
        .DE,
        .IE,
        .NL,
        .AT,
        .BE,
        .FI,
        .IT,
        .LU,
        .PT,
        .ES,
        .SG,
        .NZ,
        .AU
    ])
    func isPOSCardPaymentEnabled_is_true_for_supported_country(country: CountryCode) {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: country)

        // When / Then
        #expect(configuration.isPOSCardPaymentEnabled == true)
    }

    @Test func isPOSCardPaymentEnabled_is_false_for_Canada_until_Interac_lands() {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .CA)

        // When / Then — CA is reported as supported by IPP but explicitly excluded from POS.
        #expect(configuration.isSupportedCountry == true)
        #expect(configuration.isPOSCardPaymentEnabled == false)
    }

    @Test(arguments: [
        CountryCode.JP,
        .MX,
        .IN,
        .BR
    ])
    func isPOSCardPaymentEnabled_is_false_for_unsupported_country(country: CountryCode) {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: country)

        // When / Then
        #expect(configuration.isPOSCardPaymentEnabled == false)
    }
}
