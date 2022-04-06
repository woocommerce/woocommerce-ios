import XCTest
@testable import WooCommerce

final class SelectProductsViewModelTests: XCTestCase {

    func test_navigationTitle_is_correct_for_default_screen() {
        // Given
        let viewModel = SelectProductsViewModel()

        // Then
        XCTAssertEqual(viewModel.navigationTitle, NSLocalizedString("Select products", comment: ""))
    }

    func test_navigationTitle_is_correct_for_exclusion_screen() {
        // Given
        let viewModel = SelectProductsViewModel(isExclusion: true)

        // Then
        XCTAssertEqual(viewModel.navigationTitle, NSLocalizedString("Exclude products", comment: ""))
    }
}
