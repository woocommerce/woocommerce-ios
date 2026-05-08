import Foundation
import Testing
@testable import WooCommerce

struct WidgetSiteTests {

    @Test func timezone_when_identifier_is_valid_then_returns_named_zone() {
        // Given
        let site = WidgetSite(siteID: 1,
                              name: "Site",
                              timezoneIdentifier: "Europe/Madrid",
                              gmtOffset: 1,
                              currencySettings: nil)

        // When
        let timezone = site.timezone

        // Then
        #expect(timezone.identifier == "Europe/Madrid")
    }

    @Test func timezone_when_identifier_is_invalid_then_falls_back_to_gmt_offset() {
        // Given
        let site = WidgetSite(siteID: 1,
                              name: "Site",
                              timezoneIdentifier: "Not/A/Real/Zone",
                              gmtOffset: -5,
                              currencySettings: nil)

        // When
        let timezone = site.timezone

        // Then
        #expect(timezone.secondsFromGMT() == Int(-5 * 3600))
    }

    @Test func timezone_when_identifier_is_empty_then_falls_back_to_gmt_offset() {
        // Given
        let site = WidgetSite(siteID: 1,
                              name: "Site",
                              timezoneIdentifier: "",
                              gmtOffset: 2,
                              currencySettings: nil)

        // When
        let timezone = site.timezone

        // Then
        #expect(timezone.secondsFromGMT() == Int(2 * 3600))
    }

    @Test func encoded_then_decoded_round_trip_preserves_fields() throws {
        // Given
        let original = WidgetSite(siteID: 42,
                                  name: "Test Site",
                                  timezoneIdentifier: "America/New_York",
                                  gmtOffset: -5,
                                  currencySettings: nil)

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetSite.self, from: data)

        // Then
        #expect(decoded == original)
    }
}
