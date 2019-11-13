import XCTest
@testable import WooCommerce

final class UIColor_Muriel_Tests: XCTestCase {
    func testBlueColorObtainedMatchesMurielSpec() {
        let color = ColorStudio(name: .blue)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(color))
    }

    func testBlueColorWithShadeObtainedMatchesMurielSpec() {
        let colorName = ColorStudioName.blue
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(colorName))
    }

    func testCeladonColorObtainedMatchesMurielSpec() {
        let colorName = ColorStudio(name: .celadon)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(colorName))
    }

    func testCeladonColorWithShadeObtainedMatchesMurielSpec() {
        let colorName = ColorStudioName.celadon
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(colorName))
    }

    func testGrayColorObtainedMatchesMurielSpec() {
        let colorName = ColorStudio(name: .gray)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(colorName))
    }

    func testGrayColorWithShadeObtainedMatchesMurielSpec() {
        let colorName = ColorStudioName.gray
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(colorName))
    }

    func testGreenColorObtainedMatchesMurielSpec() {
        let colorName = ColorStudio(name: .green)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(colorName))
    }

    func testGreenColorWithShadeObtainedMatchesMurielSpec() {
        let colorName = ColorStudioName.green
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(colorName))
    }

    func testOrangeColorObtainedMatchesMurielSpec() {
        let colorName = ColorStudio(name: .orange)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(colorName))
    }

    func testOrangeColorWithShadeObtainedMatchesMurielSpec() {
        let colorName = ColorStudioName.orange
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(colorName))
    }

    func testPinkColorObtainedMatchesMurielSpec() {
        let colorName = ColorStudio(name: .pink)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(colorName))
    }

    func testPinkColorWithShadeObtainedMatchesMurielSpec() {
        let colorName = ColorStudioName.pink
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(colorName))
    }

    func testPurpleColorObtainedMatchesMurielSpec() {
        let colorName = ColorStudio(name: .purple)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(colorName))
    }

    func testPurpleColorWithShadeObtainedMatchesMurielSpec() {
        let colorName = ColorStudioName.purple
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(colorName))
    }

    func testYellowColorObtainedMatchesMurielSpec() {
        let colorName = ColorStudio(name: .yellow)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(colorName))
    }

    func testYellowColorWithShadeObtainedMatchesMurielSpec() {
        let colorName = ColorStudioName.yellow
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(colorName))
    }

    func testWooCommercePurpleColorObtainedMatchesMurielSpec() {
        let colorName = ColorStudio(name: .wooCommercePurple)
        XCTAssertTrue(colorAssetObtainedMatchesMuriel(colorName))
    }

    func testWooCommercePurpleColorWithShadeObtainedMatchesMurielSpec() {
        let colorName = ColorStudioName.wooCommercePurple
        XCTAssertTrue(colorAssetObtainedForColorNameMatchesMurielWithAllShades(colorName))
    }

    /// A somewhat indirect way to test that color assets are present in the project
    ///
    private func colorAssetObtainedMatchesMuriel(_ murielColor: ColorStudio) -> Bool {
        let color = UIColor.withColorStudio(murielColor)
        let assetColor = UIColor(named: murielColor.assetName())

        return color == assetColor
    }

    /// A somewhat indirect way to test that color assets are present in the project
    /// for all shades of a given color name
    private func colorAssetObtainedForColorNameMatchesMurielWithAllShades(_ name: ColorStudioName) -> Bool {
        let allShades = ColorStudioShade.allCases

        return allShades.map {
            let colorStudio = ColorStudio(name: name, shade: $0)
            let color = UIColor.withColorStudio(colorStudio)
            let assetColor = UIColor(named: colorStudio.assetName())

            return color == assetColor
        }.reduce(true, { $0 && $1 })
    }
}
