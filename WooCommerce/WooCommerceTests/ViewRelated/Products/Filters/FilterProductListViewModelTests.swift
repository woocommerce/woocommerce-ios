import XCTest
@testable import WooCommerce

final class FilterProductListViewModelTests: XCTestCase {
    func testCriteriaWithDefaultFilters() {
        let filters = FilterProductListViewModel.Filters()
        let viewModel = FilterProductListViewModel(filters: filters)
        let expectedCriteria = FilterProductListViewModel.Filters(stockStatus: nil, productStatus: nil, productType: nil, numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func testCriteriaWithNonNilFilters() {
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock, productStatus: .draft, productType: .grouped, numberOfActiveFilters: 3)
        let viewModel = FilterProductListViewModel(filters: filters)
        let expectedCriteria = filters
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func testCriteriaAfterClearingAllNonNilFilters() {
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock, productStatus: .draft, productType: .grouped, numberOfActiveFilters: 3)
        let viewModel = FilterProductListViewModel(filters: filters)
        viewModel.clearAll()
        let expectedCriteria = FilterProductListViewModel.Filters(stockStatus: nil, productStatus: nil, productType: nil, numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }
}
