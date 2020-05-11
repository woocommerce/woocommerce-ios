import XCTest
@testable import WooCommerce

final class FilterProductListViewModel_numberOfActiveFiltersTests: XCTestCase {
    func testZeroActiveFilters() {
        let filters = FilterProductListViewModel.Filters()
        let filterTypeViewModels = createFilterTypeViewModels(filters: filters)
        XCTAssertEqual(filterTypeViewModels.numberOfActiveFilters, 0)
    }

    func testOneActiveFilter() {
        let filters = FilterProductListViewModel.Filters(stockStatus: nil, productStatus: .draft, productType: nil, numberOfActiveFilters: 0)
        let filterTypeViewModels = createFilterTypeViewModels(filters: filters)
        XCTAssertEqual(filterTypeViewModels.numberOfActiveFilters, 1)
    }

    func testTwoActiveFilters() {
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock, productStatus: .publish, productType: nil, numberOfActiveFilters: 0)
        let filterTypeViewModels = createFilterTypeViewModels(filters: filters)
        XCTAssertEqual(filterTypeViewModels.numberOfActiveFilters, 2)
    }

    func testThreeActiveFilters() {
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock, productStatus: .publish, productType: .variable, numberOfActiveFilters: 0)
        let filterTypeViewModels = createFilterTypeViewModels(filters: filters)
        XCTAssertEqual(filterTypeViewModels.numberOfActiveFilters, 3)
    }
}

private extension FilterProductListViewModel_numberOfActiveFiltersTests {
    func createFilterTypeViewModels(filters: FilterProductListViewModel.Filters) -> [FilterTypeViewModel] {
        return [
            FilterProductListViewModel.ProductListFilter.stockStatus.createViewModel(filters: filters),
            FilterProductListViewModel.ProductListFilter.productStatus.createViewModel(filters: filters),
            FilterProductListViewModel.ProductListFilter.productType.createViewModel(filters: filters)
        ]
    }
}
