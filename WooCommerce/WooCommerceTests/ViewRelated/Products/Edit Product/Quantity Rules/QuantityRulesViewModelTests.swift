import XCTest
@testable import WooCommerce

final class QuantityRulesViewModelTests: XCTestCase {

    func test_view_model_returns_placeholders_for_nil_quantities() {
        // Given
        let viewModel = QuantityRulesViewModel(minQuantity: nil, maxQuantity: nil, groupOf: nil)

        // Then
        XCTAssertEqual(viewModel.minQuantity, Placeholders.noMinQuantity)
        XCTAssertEqual(viewModel.maxQuantity, Placeholders.noMaxQuantity)
        XCTAssertEqual(viewModel.groupOf, Placeholders.noGroupOfQuantity)
    }

    func test_view_model_returns_placeholders_for_empty_quantities() {
        // Given
        let viewModel = QuantityRulesViewModel(minQuantity: "", maxQuantity: "", groupOf: "")

        // Then
        XCTAssertEqual(viewModel.minQuantity, Placeholders.noMinQuantity)
        XCTAssertEqual(viewModel.maxQuantity, Placeholders.noMaxQuantity)
        XCTAssertEqual(viewModel.groupOf, Placeholders.noGroupOfQuantity)
    }

    func test_view_model_returns_quantities_when_not_nil_or_empty() {
        // Given
        let viewModel = QuantityRulesViewModel(minQuantity: "4", maxQuantity: "200", groupOf: "2")

        // Then
        XCTAssertEqual(viewModel.minQuantity, "4")
        XCTAssertEqual(viewModel.maxQuantity, "200")
        XCTAssertEqual(viewModel.groupOf, "2")
    }

}

private extension QuantityRulesViewModelTests {
    enum Placeholders {
        static let noMinQuantity = NSLocalizedString("No minimum", comment: "Description when no minimum quantity is set in quantity rules.")
        static let noMaxQuantity = NSLocalizedString("No maximum", comment: "Description when no maximum quantity is set in quantity rules.")
        static let noGroupOfQuantity = NSLocalizedString("Not grouped", comment: "Description when no 'group of' quantity is set in quantity rules.")
    }
}
