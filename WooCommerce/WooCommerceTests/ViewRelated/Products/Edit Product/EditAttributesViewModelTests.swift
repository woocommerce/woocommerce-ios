import XCTest
@testable import WooCommerce

final class EditAttributesViewModelTests: XCTestCase {

    func test_done_button_is_visible_when_allowing_variation_creation() {
        // Given, Then
        let viewModel = EditAttributesViewModel(product: .init(), allowVariationCreation: true)

        // Then
        XCTAssertTrue(viewModel.showDoneButton)
    }

    func test_done_button_is_not_visible_when_not_allowing_variation_creation() {
        // Given, Then
        let viewModel = EditAttributesViewModel(product: .init(), allowVariationCreation: false)

        // Then
        XCTAssertFalse(viewModel.showDoneButton)
    }
}
