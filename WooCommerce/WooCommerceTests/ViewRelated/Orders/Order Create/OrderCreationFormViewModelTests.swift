import XCTest

@testable import WooCommerce

/// Test cases for `OrderCreationFormViewModel`
///
final class OrderCreationFormViewModelTests: XCTestCase {

    func test_viewModel_is_correct_when_created_without_existing_draft_order() {
        // When
        let viewModel = OrderCreationFormViewModel()

        // Then
        XCTAssertEqual(viewModel.sections.count, 4)
        viewModel.sections.forEach { section in
            XCTAssertEqual(section.rows.count, 1)
        }
        XCTAssertEqual(viewModel.sections.first?.rows.first, .summary)
    }
}
