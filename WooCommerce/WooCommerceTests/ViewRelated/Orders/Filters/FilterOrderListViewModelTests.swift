import XCTest
@testable import WooCommerce
@testable import Yosemite

final class FilterOrderListViewModelTests: XCTestCase {
    func test_criteria_with_default_filters() {
        // Given
        let filters = FilterOrderListViewModel.Filters()

        // When
        let viewModel = FilterOrderListViewModel(filters: filters, allowedStatuses: [], siteID: 1)

        // Then
        let expectedCriteria = FilterOrderListViewModel.Filters(orderStatus: nil,
                                                                dateRange: nil,
                                                                product: nil,
                                                                numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func test_criteria_with_non_nil_filters() {
        // Given
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.processing],
                                                       dateRange: OrderDateRangeFilter(filter: .today),
                                                       product: FilterOrdersByProduct(id: 1, name: "Sample product"),
                                                       numberOfActiveFilters: 3)

        // When
        let viewModel = FilterOrderListViewModel(filters: filters, allowedStatuses: [], siteID: 1)

        // Then
        let expectedCriteria = filters
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func test_criteria_after_clearing_all_non_nil_filters() {
        // Given
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.completed],
                                                       dateRange: OrderDateRangeFilter(filter: .last7Days),
                                                       product: FilterOrdersByProduct(id: 1, name: "Sample product"),
                                                       numberOfActiveFilters: 3)

        // When
        let viewModel = FilterOrderListViewModel(filters: filters, allowedStatuses: [], siteID: 1)
        viewModel.clearAll()

        // Then
        let expectedCriteria = FilterOrderListViewModel.Filters(orderStatus: nil,
                                                                dateRange: nil,
                                                                product: nil,
                                                                numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }
}
