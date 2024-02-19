import XCTest
@testable import Storage

final class GeneralStoreSettingsTests: XCTestCase {
    func test_basic_encoding_decoding() throws {
        let expected = GeneralStoreSettings(
            isTelemetryAvailable: true,
            telemetryLastReportedTime: .init(),
            areSimplePaymentTaxesEnabled: true,
            preferredInPersonPaymentGateway: "woocommerce-payments")
        let encoded = try JSONEncoder().encode(expected)
        let decoded = try JSONDecoder().decode(GeneralStoreSettings.self, from: encoded)
        XCTAssertEqual(expected, decoded)
    }

    func test_it_returns_default_analytics_cards_when_none_set() {
        // Given
        let expectedCards = AnalyticsCard.defaultCards
        let settings = GeneralStoreSettings()

        // Then
        assertEqual(expectedCards, settings.analyticsHubCards)
    }
}
