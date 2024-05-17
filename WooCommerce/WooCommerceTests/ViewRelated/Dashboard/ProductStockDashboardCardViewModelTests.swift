import XCTest
@testable import WooCommerce

final class ProductStockDashboardCardViewModelTests: XCTestCase {

    func test_initial_stock_type_is_low_stock() {
        // Given
        let viewModel = ProductStockDashboardCardViewModel(siteID: 123)

        // Then
        XCTAssertEqual(viewModel.selectedStockType, .lowStock)
    }

    func test_updateStockType_updates_selected_stock_type() {
        // Given
        let viewModel = ProductStockDashboardCardViewModel(siteID: 123)

        // When
        viewModel.updateStockType(.outOfStock)

        // Then
        XCTAssertEqual(viewModel.selectedStockType, .outOfStock)
    }

}
