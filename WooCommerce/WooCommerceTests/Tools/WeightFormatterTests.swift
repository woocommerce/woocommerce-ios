import XCTest
@testable import WooCommerce

final class WeightFormatterTests: XCTestCase {

    func test_weightFormat_returns_expected_values() {
        // Given
        let formatterWithoutSpace = WeightFormatter(weightUnit: "kg", withSpace: false)
        let formatterWithSpace = WeightFormatter(weightUnit: "lbs", withSpace: true)

        // Then
        XCTAssertEqual(formatterWithoutSpace.formatWeight(weight: "16"), "16kg")
        XCTAssertEqual(formatterWithSpace.formatWeight(weight: "13.5"), "13.5 lbs")
    }
}
