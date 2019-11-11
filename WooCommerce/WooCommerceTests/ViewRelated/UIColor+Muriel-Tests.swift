import XCTest
@testable import WooCommerce

final class UIColor_Muriel_Tests: XCTestCase {
    func testBlueColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .blue)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testCeladonColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .celadon)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testGrayColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .gray)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testGreenColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .green)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testOrangeColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .orange)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testPinkColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .pink)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testPurpleColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .purple)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testYellowColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .yellow)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testWooCommercePurpleColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .wooCommercePurple)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    /// A somewhat indirect way to test that color assets are present in the project
    ///
    private func colorAssetObtainedMatchesMuriel(_ murielColor: MurielColor) -> Bool {
        let color = UIColor.muriel(color: murielColor)
        let assetColor = UIColor(named: murielColor.assetName())

        return color == assetColor
    }
}
