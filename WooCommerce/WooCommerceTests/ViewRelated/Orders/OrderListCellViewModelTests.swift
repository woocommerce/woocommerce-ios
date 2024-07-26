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
        let viewModel = OrderListCellViewModel(order: order, currencySettings: ServiceLocator.currencySettings)

        // Then
        let formatted = viewModel.dateCreated

        XCTAssertFalse(formatted.contains(expectedYearString))
    }

    func test_dateCreated_includes_the_year_for_dates_that_are_not_in_the_same_year() {
        // Given
        let order = MockOrders().sampleOrder()
        let expectedYearString = DateFormatter.yearFormatter.string(from: order.dateCreated)

        // When
        let viewModel = OrderListCellViewModel(order: order, currencySettings: ServiceLocator.currencySettings)

        // Then
        let formatted = viewModel.dateCreated

        XCTAssertTrue(formatted.contains(expectedYearString))
    }

    func test_status_from_order_is_used() {
        // Given
        let order = MockOrders().sampleOrder()

        // When
        let viewModel = OrderListCellViewModel(order: order, currencySettings: ServiceLocator.currencySettings)

        // Then
        XCTAssertEqual(viewModel.status, order.status)
        XCTAssertEqual(viewModel.statusString, order.status.localizedName)
    }

    func test_OrderListCell_accessoryView_uses_chevron_with_tertiaryLabel_tint_as_disclosure_indicator() {
        // Given
        let order = MockOrders().sampleOrder()
        let expectedImage = UIImage(systemName: "chevron.forward")

        // When
        let viewModel = OrderListCellViewModel(order: order, currencySettings: ServiceLocator.currencySettings)

        // Then
        guard let accessoryView = viewModel.accessoryView else {
            return XCTFail("Cell does not have an accessory view.")
        }
        XCTAssertEqual(accessoryView.image, expectedImage)
        XCTAssertEqual(accessoryView.tintColor, .tertiaryLabel)
    }
}
