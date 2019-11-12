import XCTest
@testable import WooCommerce

final class UIColor_Muriel_Tests: XCTestCase {
    func testBlueColorObtainedMatchesMurielSpec() {
        let murielColor = ColorStudio(name: .blue)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testBlueColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = ColorStudioName.blue
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testCeladonColorObtainedMatchesMurielSpec() {
        let murielColor = ColorStudio(name: .celadon)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testCeladonColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = ColorStudioName.celadon
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testGrayColorObtainedMatchesMurielSpec() {
        let murielColor = ColorStudio(name: .gray)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testGrayColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = ColorStudioName.gray
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testGreenColorObtainedMatchesMurielSpec() {
        let murielColor = ColorStudio(name: .green)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testGreenColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = ColorStudioName.green
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testOrangeColorObtainedMatchesMurielSpec() {
        let murielColor = ColorStudio(name: .orange)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testOrangeColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = ColorStudioName.orange
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testPinkColorObtainedMatchesMurielSpec() {
        let murielColor = ColorStudio(name: .pink)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testPinkColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = ColorStudioName.pink
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testPurpleColorObtainedMatchesMurielSpec() {
        let murielColor = ColorStudio(name: .purple)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testPurpleColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = ColorStudioName.purple
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testYellowColorObtainedMatchesMurielSpec() {
        let murielColor = ColorStudio(name: .yellow)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testYellowColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = ColorStudioName.yellow
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    func testWooCommercePurpleColorObtainedMatchesMurielSpec() {
        let murielColor = ColorStudio(name: .wooCommercePurple)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(murielColor))
    }

    func testWooCommercePurpleColorWithShadeObtainedMatchesMurielSpec() {
        let murielColorName = ColorStudioName.wooCommercePurple
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(murielColorName))
    }

    /// A somewhat indirect way to test that color assets are present in the project
    ///
    private func colorAssetObtainedMatchesMuriel(_ murielColor: ColorStudio) -> Bool {
        let color = UIColor.muriel(color: murielColor)
        let assetColor = UIColor(named: murielColor.assetName())

        return color == assetColor
    }

    /// A somewhat indirect way to test that color assets are present in the project
    /// for all shades of a given color name
    private func colorAssetObtainedForColorNameMatchesMurielWithAllShades(_ name: ColorStudioName) -> Bool {
        let allShades = ColorStudioShade.allCases

        return allShades.map {
            let murielColor = ColorStudio(name: name, shade: $0)
            let color = UIColor.muriel(color: murielColor)
            let assetColor = UIColor(named: murielColor.assetName())

            return color == assetColor
        }.reduce(true, { $0 && $1 })
    }
}
