import XCTest
@testable import WooCommerce
@testable import Yosemite

final class FilterProductListViewModelProductListFilterTests: XCTestCase {
    let filterProductCategory = ProductCategory(categoryID: 0, siteID: 0, parentID: 0, name: "", slug: "")

    func testCreatingStockStatusFilterTypeViewModel() {
        let filterType = FilterProductListViewModel.ProductListFilter.stockStatus
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         productType: .grouped,
                                                         productCategory: filterProductCategory,
                                                         numberOfActiveFilters: 4)
        let viewModel = filterType.createViewModel(filters: filters)
        XCTAssertEqual(viewModel.selectedValue as? ProductStockStatus, .inStock)
    }

    func testCreatingProductStatusFilterTypeViewModel() {
        let filterType = FilterProductListViewModel.ProductListFilter.productStatus
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         productType: .grouped,
                                                         productCategory: filterProductCategory,
                                                         numberOfActiveFilters: 4)
        let viewModel = filterType.createViewModel(filters: filters)
        XCTAssertEqual(viewModel.selectedValue as? ProductStatus, .draft)
    }

    func testCreatingProductTypeFilterTypeViewModel() {
        let filterType = FilterProductListViewModel.ProductListFilter.productType
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         productType: .grouped,
                                                         productCategory: filterProductCategory,
                                                         numberOfActiveFilters: 4)
        let viewModel = filterType.createViewModel(filters: filters)
        XCTAssertEqual(viewModel.selectedValue as? ProductType, .grouped)
    }

    func testCreatingProductCategoryFilterTypeViewModel() {
        let filterType = FilterProductListViewModel.ProductListFilter.productCategory

        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         productType: .grouped,
                                                         productCategory: filterProductCategory,
                                                         numberOfActiveFilters: 4)
        let viewModel = filterType.createViewModel(filters: filters)
        XCTAssertEqual(viewModel.selectedValue as? ProductCategory, filterProductCategory)
    }
}
