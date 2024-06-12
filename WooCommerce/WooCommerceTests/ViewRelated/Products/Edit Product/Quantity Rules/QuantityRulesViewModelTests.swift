import XCTest
@testable import WooCommerce

final class QuantityRulesViewModelTests: XCTestCase {
    func test_view_model_returns_empty_string_for_nil_quantities() {
        // Given
        let viewModel = QuantityRulesViewModel(minQuantity: nil, maxQuantity: nil, groupOf: nil) {_, _ in }

        // Then
        XCTAssertEqual(viewModel.minQuantity, "")
        XCTAssertEqual(viewModel.maxQuantity, "")
        XCTAssertEqual(viewModel.groupOf, "")
    }

    func test_view_model_returns_empty_string_for_empty_quantities() {
        // Given
        let viewModel = QuantityRulesViewModel(minQuantity: "", maxQuantity: "", groupOf: "") {_, _ in }

        // Then
        XCTAssertEqual(viewModel.minQuantity, "")
        XCTAssertEqual(viewModel.maxQuantity, "")
        XCTAssertEqual(viewModel.groupOf, "")
    }

    func test_view_model_returns_quantities_when_not_nil_or_empty() {
        // Given
        let viewModel = QuantityRulesViewModel(minQuantity: "4", maxQuantity: "200", groupOf: "2") {_, _ in }

        // Then
        XCTAssertEqual(viewModel.minQuantity, "4")
        XCTAssertEqual(viewModel.maxQuantity, "200")
        XCTAssertEqual(viewModel.groupOf, "2")
    }

    func test_onDoneButtonPressed_calls_onCompletion_with_values() {
        let newMinQuantity = "5"
        let newMaxQuantity = "10"
        let newGroupOfValue = "5"

        var passedMinQuantity: String?
        var passedMaxQuantity: String?
        var passedGroupOfValue: String?

        let viewModel = QuantityRulesViewModel(minQuantity: "4", maxQuantity: "200", groupOf: "2") { rules, hasUnchangedValues in
            passedMinQuantity = rules.minQuantity
            passedMaxQuantity = rules.maxQuantity
            passedGroupOfValue = rules.groupOf
        }

        viewModel.minQuantity = newMinQuantity
        viewModel.maxQuantity = newMaxQuantity
        viewModel.groupOf = newGroupOfValue

        viewModel.onDoneButtonPressed()

        XCTAssertEqual(passedMinQuantity, newMinQuantity)
        XCTAssertEqual(passedMaxQuantity, newMaxQuantity)
        XCTAssertEqual(passedGroupOfValue, newGroupOfValue)
    }
}
