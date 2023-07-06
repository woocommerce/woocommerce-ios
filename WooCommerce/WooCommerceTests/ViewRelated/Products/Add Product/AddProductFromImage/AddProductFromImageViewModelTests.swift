import TestKit
import XCTest
import Yosemite

@testable import WooCommerce

@MainActor
final class AddProductFromImageViewModelTests: XCTestCase {
    func test_initial_name_is_empty() throws {
        // Given
        let viewModel = AddProductFromImageViewModel()

        // Then
        XCTAssertEqual(viewModel.name, "")
    }

    func test_initial_description_is_empty() throws {
        // Given
        let viewModel = AddProductFromImageViewModel()

        // Then
        XCTAssertEqual(viewModel.description, "")
    }
}
