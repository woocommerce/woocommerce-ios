import TestKit
import XCTest

@testable import WooCommerce

@MainActor
final class AddProductFromImageViewModelTests: XCTestCase {
    func test_initial_name_is_empty() throws {
        // Given
        let viewModel = AddProductFromImageViewModel(onAddImage: { _ in nil })

        // Then
        XCTAssertEqual(viewModel.name, "")
    }

    func test_initial_description_is_empty() throws {
        // Given
        let viewModel = AddProductFromImageViewModel(onAddImage: { _ in nil })

        // Then
        XCTAssertEqual(viewModel.description, "")
    }
}
