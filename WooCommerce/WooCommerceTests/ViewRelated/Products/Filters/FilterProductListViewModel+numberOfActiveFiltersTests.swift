import XCTest
@testable import WooCommerce

final class FilterProductListViewModel_numberOfActiveFiltersTests: XCTestCase {
    func testZeroActiveFilters() {
        let filters = FilterProductListViewModel.Filters(stockStatus: nil, productStatus: nil, productType: nil)
        let viewModel = FilterProductListViewModel(filters: filters)
        XCTAssertEqual(viewModel.numberOfActiveFilters, 0)
    }

    func testOneActiveFilter() {
        let filters = FilterProductListViewModel.Filters(stockStatus: nil, productStatus: .publish, productType: nil)
        let viewModel = FilterProductListViewModel(filters: filters)
        XCTAssertEqual(viewModel.numberOfActiveFilters, 1)
    }

    func testTwoActiveFilters() {
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock, productStatus: .publish, productType: nil)
        let viewModel = FilterProductListViewModel(filters: filters)
        XCTAssertEqual(viewModel.numberOfActiveFilters, 2)
    }

    func testThreeActiveFilters() {
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock, productStatus: .publish, productType: .variable)
        let viewModel = FilterProductListViewModel(filters: filters)
        XCTAssertEqual(viewModel.numberOfActiveFilters, 3)
    }
}
