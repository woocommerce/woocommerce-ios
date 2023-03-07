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
}
