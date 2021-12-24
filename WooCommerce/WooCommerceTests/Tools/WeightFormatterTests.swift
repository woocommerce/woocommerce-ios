import XCTest
@testable import WooCommerce

final class WeightFormatterTests: XCTestCase {

    func test_weightFormat_returns_expected_values() {
        // Given
        let formatter = WeightFormatter(weightUnit: "lbs")

        // Then
        XCTAssertEqual(formatter.formatWeight(weight: "13.5"), "13.5 lb")
    }

    func test_weightFormat_returns_expected_values_if_weight_is_empty_or_nil() {
        // Given
        let formatter = WeightFormatter(weightUnit: "lbs")

        // Then
        XCTAssertEqual(formatter.formatWeight(weight: ""), "0 lb")
        XCTAssertEqual(formatter.formatWeight(weight: nil), "0 lb")
    }

    func test_weightFormat_returns_localized_value_for_known_unit() {
        // Given
        let formatter = WeightFormatter(weightUnit: "lbs", locale: Locale(identifier: "zh"))

        // Then
        XCTAssertEqual(formatter.formatWeight(weight: "16"), "16磅")
    }

    func test_weightFormat_returns_fallback_value_for_unknown_unit() {
        // Given
        let formatter = WeightFormatter(weightUnit: "woos", locale: Locale(identifier: "zh"))

        // Then
        XCTAssertEqual(formatter.formatWeight(weight: "16"), "16 woos")
    }
}
