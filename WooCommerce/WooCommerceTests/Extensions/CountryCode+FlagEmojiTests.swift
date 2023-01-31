import XCTest
@testable import WooCommerce

final class CountryCode_FlagEmojiTests: XCTestCase {
    func test_us_flag_emoji_is_returned_for_US() {
        // Given
        let countryCode = SiteAddress.CountryCode.US

        // Then
        XCTAssertEqual(countryCode.flagEmoji, "🇺🇸")
    }
}
