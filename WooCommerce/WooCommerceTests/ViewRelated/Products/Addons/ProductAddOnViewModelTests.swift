import XCTest
import TestKit

@testable import WooCommerce

class ProductAddOnViewModelTests: XCTestCase {

    func test_view_model_shows_description_when_price_is_not_empty() {
        // Given
        let viewModel = ProductAddOnViewModel(name: "", description: "", price: "$20.99", options: [])

        // Then & When
        XCTAssertTrue(viewModel.showDescription)
        XCTAssertTrue(viewModel.showPrice)
    }

    func test_view_model_hides_description_and_price_when_empty() {
        // Given
        let viewModel = ProductAddOnViewModel(name: "", description: "", price: "", options: [
            .init(name: "", price: "")
        ])

        // Then & When
        XCTAssertFalse(viewModel.showDescription)
        XCTAssertFalse(viewModel.showPrice)
        XCTAssertFalse(viewModel.options[0].showPrice)
    }

    func test_view_model_shows_description_and_price_when_not_empty() {
        // Given
        let viewModel = ProductAddOnViewModel(name: "", description: "Description", price: "$20.99", options: [
            .init(name: "", price: "$20.99")
        ])

        // Then & When
        XCTAssertTrue(viewModel.showDescription)
        XCTAssertTrue(viewModel.showPrice)
        XCTAssertTrue(viewModel.options[0].showPrice)
    }
}
