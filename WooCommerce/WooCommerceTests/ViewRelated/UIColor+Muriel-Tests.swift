import XCTest
@testable import WooCommerce

final class UIColor_Muriel_Tests: XCTestCase {
    func testBlueColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .blue)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testBlueColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = MurielColorName.blue
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testCeladonColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .celadon)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testCeladonColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = MurielColorName.celadon
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testGrayColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .gray)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testGrayColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = MurielColorName.gray
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testGreenColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .green)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testGreenColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = MurielColorName.green
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testOrangeColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .orange)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testOrangeColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = MurielColorName.orange
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testPinkColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .pink)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testPinkColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = MurielColorName.pink
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testPurpleColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .purple)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testPurpleColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = MurielColorName.purple
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testYellowColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .yellow)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testYellowColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = MurielColorName.yellow
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testWooCommercePurpleColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor(name: .wooCommercePurple)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testWooCommercePurpleColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = MurielColorName.wooCommercePurple
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    /// A somewhat indirect way to test that color assets are present in the project
    ///
    private func colorAssetObtainedMatchesMuriel(_ murielColor: MurielColor) -> Bool {
        let color = UIColor.muriel(color: murielColor)
        let assetColor = UIColor(named: murielColor.assetName())

        return color == assetColor
    }

    /// A somewhat indirect way to test that color assets are present in the project
    /// for all shades of a given color name
    private func colorAssetObtainedForColorNameMatchesMurielWithAllShades(_ name: MurielColorName) -> Bool {
        let allShades = MurielColorShade.allCases

        return allShades.map {
            let murielColor = MurielColor(name: name, shade: $0)
            let color = UIColor.muriel(color: murielColor)
            let assetColor = UIColor(named: murielColor.assetName())

            return color == assetColor
        }.reduce(true, { $0 && $1 })
    }
}
