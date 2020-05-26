import XCTest
@testable import WooCommerce
@testable import Yosemite

final class FilterProductListViewModelProductListFilterTests: XCTestCase {
    func testCreatingStockStatusFilterTypeViewModel() {
        let filterType = FilterProductListViewModel.ProductListFilter.stockStatus
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock, productStatus: .draft, productType: .grouped, numberOfActiveFilters: 3)
        let viewModel = filterType.createViewModel(filters: filters)
        XCTAssertEqual(viewModel.selectedValue as? ProductStockStatus, .inStock)
    }

    func testCreatingProductStatusFilterTypeViewModel() {
        let filterType = FilterProductListViewModel.ProductListFilter.productStatus
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock, productStatus: .draft, productType: .grouped, numberOfActiveFilters: 3)
        let viewModel = filterType.createViewModel(filters: filters)
        XCTAssertEqual(viewModel.selectedValue as? ProductStatus, .draft)
    }

    func testCreatingProductTypeFilterTypeViewModel() {
        let filterType = FilterProductListViewModel.ProductListFilter.productType
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock, productStatus: .draft, productType: .grouped, numberOfActiveFilters: 3)
        let viewModel = filterType.createViewModel(filters: filters)
        XCTAssertEqual(viewModel.selectedValue as? ProductType, .grouped)
    }
}
