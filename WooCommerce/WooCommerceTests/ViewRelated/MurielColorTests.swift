import XCTest
@testable import WooCommerce

final class MurielColorTests: XCTestCase {
    func testPinkColorMatchesAssetName() {
        XCTAssertTrue(colorMatchesExpectation(color: ColorStudio.pink, expectation: Expectations.pink))
    }

    func testWooCommercePurpleMatchesAssetName() {
        XCTAssertTrue(colorMatchesExpectation(color: ColorStudio.wooCommercePurple, expectation: Expectations.wooCommercePurple))
    }

    func testRedMatchesAssetName() {
        XCTAssertTrue(colorMatchesExpectation(color: ColorStudio.red, expectation: Expectations.red))
    }

    func testGrayMatchesAssetName() {
        XCTAssertTrue(colorMatchesExpectation(color: ColorStudio.gray, expectation: Expectations.gray))
    }

    func testBlueMatchesAssetName() {
        XCTAssertTrue(colorMatchesExpectation(color: ColorStudio.blue, expectation: Expectations.blue))
    }

    func testGreenMatchesAssetName() {
        XCTAssertTrue(colorMatchesExpectation(color: ColorStudio.green, expectation: Expectations.green))
    }

    func testWarningMatchesAssetName() {
        XCTAssertTrue(colorMatchesExpectation(color: ColorStudio.yellow, expectation: Expectations.yellow))
    }

    private func colorMatchesExpectation(color: ColorStudio, expectation: String) -> Bool {
        let assetName = color.assetName()

        return assetName == expectation
    }
}

extension MurielColorTests {
    enum Expectations {
        static let pink = "Pink50"
        static let wooCommercePurple = "WooCommercePurple50"
        static let red = "Red50"
        static let gray = "Gray50"
        static let blue = "Blue50"
        static let green = "Green50"
        static let yellow = "Yellow50"
    }
}
