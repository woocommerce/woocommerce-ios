import XCTest
@testable import WooCommerce

final class UIColor_Muriel_Tests: XCTestCase {
    func testGrayColorObtainedMatchesMurielSpec() {
        let murielColor = MurielColor.gray
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
