import XCTest
import SwiftUI

@testable import WooFoundation

final class Color_RGBStringDecoding_Tests: XCTestCase {

    func test_init_with_rgb_string_for_white_creates_white() throws {
        let whiteRGBString = "rgba(255, 255, 255, 1)"
        let actualColor = try XCTUnwrap(try? Color(rgbString: whiteRGBString))
        assertEqual(Color.white, actualColor)
    }

    func test_init_with_rgb_string_for_non_opaque_red_creates_expected_color() throws {
        let nonOpaqueRedRGBString = "rgba(255, 0, 0, 0.5)"
        let actualColor = try XCTUnwrap(try? Color(rgbString: nonOpaqueRedRGBString))
        assertEqual(Color.init(red: 1, green: 0, blue: 0, opacity: 0.5), actualColor)
    }

    // N.B. decimals as color input isn't really a valid rgba string, but we can accept them
    func test_init_with_rgb_string_with_decimals_creates_expected_color() throws {
        let whiteRGBStringWithDecimals = "rgba(255.0, 255.0, 255.0, 1.0)"
        let actualColor = try XCTUnwrap(try? Color(rgbString: whiteRGBStringWithDecimals))
        assertEqual(Color.white, actualColor)
    }

}
