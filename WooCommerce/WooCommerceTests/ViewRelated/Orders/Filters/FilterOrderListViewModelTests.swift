import XCTest
@testable import WooCommerce

final class FilterOrderListViewModelTests: XCTestCase {
    func test_criteria_With_default_filters() {
        // Given
        let filters = FilterOrderListViewModel.Filters()

        // When
        let viewModel = FilterOrderListViewModel(filters: filters)

        // Then
        let expectedCriteria = FilterOrderListViewModel.Filters(orderStatus: nil, dateRange: nil, numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func test_criteria_with_non_nil_filters() {
        // Given
        let filters = FilterOrderListViewModel.Filters(orderStatus: .processing, dateRange: .today, numberOfActiveFilters: 2)

        // When
        let viewModel = FilterOrderListViewModel(filters: filters)

        // Then
        let expectedCriteria = filters
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func test_criteria_after_clearing_all_non_nil_filters() {
        // Given
        let filters = FilterOrderListViewModel.Filters(orderStatus: .completed, dateRange: .thisWeek, numberOfActiveFilters: 2)

        // When
        let viewModel = FilterOrderListViewModel(filters: filters)
        viewModel.clearAll()

        // Then
        let expectedCriteria = FilterOrderListViewModel.Filters(orderStatus: nil, dateRange: nil, numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }
}
