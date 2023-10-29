import XCTest
@testable import WooCommerce
import WooFoundation

final class CountryCode_FlagEmojiTests: XCTestCase {
    func test_us_flag_emoji_is_returned_for_US() {
        // Given
        let countryCode = CountryCode.US

        // Then
        XCTAssertEqual(countryCode.flagEmoji, "🇺🇸")
    }
}
