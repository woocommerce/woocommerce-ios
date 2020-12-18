import XCTest
import TestKit

@testable import Yosemite
@testable import WooCommerce

final class OrderListCellViewModelTests: XCTestCase {

    func test_formatted_date_created_does_not_include_the_year_for_dates_with_the_same_year() {
        // Given
        let order = MockOrders().sampleOrderCreatedInCurrentYear()
        let viewModel = OrderListCellViewModel(order: order, status: nil)
        let expectedYearString = DateFormatter.yearFormatter.string(from: order.dateCreated)

        // Then
        let formatted = viewModel.dateCreated

        XCTAssertFalse(formatted.contains(expectedYearString))
    }

    func test_formatted_date_created_includes_the_year_for_dates_that_are_not_in_the_same_year() {
        // Given
        let order = MockOrders().sampleOrder()
        let viewModel = OrderListCellViewModel(order: order, status: nil)
        let expectedYearString = DateFormatter.yearFormatter.string(from: order.dateCreated)

        // Then
        let formatted = viewModel.dateCreated

        XCTAssertTrue(formatted.contains(expectedYearString))
    }
}
