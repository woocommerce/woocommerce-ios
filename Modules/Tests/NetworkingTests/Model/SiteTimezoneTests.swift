import Foundation
import Testing
import Fakes
@testable import NetworkingCore

struct SiteTimezoneTests {
    @Test func test_siteNamedTimezone_when_timezone_is_named_then_follows_daylight_saving_time() throws {
        // Given
        let site = Site.fake().copy(timezone: "Europe/Madrid", gmtOffset: 1)
        let winter = Date(timeIntervalSince1970: 1_705_320_000) // 2024-01-15 12:00 UTC
        let summer = Date(timeIntervalSince1970: 1_721_044_800) // 2024-07-15 12:00 UTC

        // When
        let timezone = site.siteNamedTimezone

        // Then
        #expect(timezone.identifier == "Europe/Madrid")
        #expect(timezone.secondsFromGMT(for: winter) == 3600)
        #expect(timezone.secondsFromGMT(for: summer) == 7200)
    }

    @Test(arguments: ["", "Not/A_Zone"])
    func test_siteNamedTimezone_when_timezone_is_not_a_valid_identifier_then_falls_back_to_gmtOffset(identifier: String) {
        // Given
        let site = Site.fake().copy(timezone: identifier, gmtOffset: 5.5)

        // When
        let timezone = site.siteNamedTimezone

        // Then
        #expect(timezone.secondsFromGMT() == 19800)
    }
}
