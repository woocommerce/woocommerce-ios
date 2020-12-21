import XCTest
import TestKit

import Yosemite
@testable import WooCommerce

final class OrderListCellViewModelTests: XCTestCase {

    func test_dateCreated_does_not_include_the_year_for_dates_with_the_same_year() {
        // Given
        let order = MockOrders().sampleOrderCreatedInCurrentYear()
        let expectedYearString = DateFormatter.yearFormatter.string(from: order.dateCreated)

        // When
        let viewModel = OrderListCellViewModel(order: order, status: nil)

        // Then
        let formatted = viewModel.dateCreated

        XCTAssertFalse(formatted.contains(expectedYearString))
    }

    func test_dateCreated_includes_the_year_for_dates_that_are_not_in_the_same_year() {
        // Given
        let order = MockOrders().sampleOrder()
        let expectedYearString = DateFormatter.yearFormatter.string(from: order.dateCreated)

        // When
        let viewModel = OrderListCellViewModel(order: order, status: nil)

        // Then
        let formatted = viewModel.dateCreated

        XCTAssertTrue(formatted.contains(expectedYearString))
    }

    func test_OrderStatus_is_used_when_passed_to_view_model() {
        // Given
        let order = MockOrders().sampleOrder()
        let orderStatus = OrderStatus(name: UUID().uuidString,
                                      siteID: 0,
                                      slug: UUID().uuidString,
                                      total: 0)

        // When
        let viewModel = OrderListCellViewModel(order: order, status: orderStatus)

        // Then
        XCTAssertEqual(viewModel.status, .custom(orderStatus.slug))
        XCTAssertEqual(viewModel.statusString, orderStatus.name)
    }

    func test_status_from_order_is_used_when_OrderStatus_is_nil() {
        // Given
        let order = MockOrders().sampleOrder()

        // When
        let viewModel = OrderListCellViewModel(order: order, status: nil)

        // Then
        XCTAssertEqual(viewModel.status, order.status)
        XCTAssertEqual(viewModel.statusString, order.status.rawValue)
    }
}
