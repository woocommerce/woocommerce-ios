import XCTest
@testable import WooCommerce

final class FilterProductListViewModelTests: XCTestCase {
    func testCriteriaWithDefaultFilters() {
        // Given
        let filters = FilterProductListViewModel.Filters()

        // When
        let viewModel = FilterProductListViewModel(filters: filters)

        // Then
        let expectedCriteria = FilterProductListViewModel.Filters(stockStatus: nil, productStatus: nil, productType: nil, numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func testCriteriaWithNonNilFilters() {
        // Given
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock, productStatus: .draft, productType: .grouped, numberOfActiveFilters: 3)

        // When
        let viewModel = FilterProductListViewModel(filters: filters)

        // Then
        let expectedCriteria = filters
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func testCriteriaAfterClearingAllNonNilFilters() {
        // Given
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock, productStatus: .draft, productType: .grouped, numberOfActiveFilters: 3)

        // When
        let viewModel = FilterProductListViewModel(filters: filters)
        viewModel.clearAll()

        // Then
        let expectedCriteria = FilterProductListViewModel.Filters(stockStatus: nil, productStatus: nil, productType: nil, numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }
}
