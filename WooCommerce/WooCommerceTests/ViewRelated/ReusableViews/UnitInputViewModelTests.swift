import Combine
import XCTest

@testable import WooCommerce

/// Test cases for `UnitInputViewModelTests`.
///
final class UnitInputViewModelTests: XCTestCase {

    func test_view_model_values_for_bulk_price_update() {
        // Given
        let currencySettings = CurrencySettings()
        let viewModel = UnitInputViewModel.createBulkPriceViewModel(using: currencySettings,
                                                                    onInputChange: {_ in })

        // Then
        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.placeholder, "0.00")
        XCTAssertEqual(viewModel.style, .secondary)
    }
}
