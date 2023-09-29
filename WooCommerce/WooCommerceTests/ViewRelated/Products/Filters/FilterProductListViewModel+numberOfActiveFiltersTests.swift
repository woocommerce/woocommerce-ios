import XCTest
@testable import WooCommerce
@testable import Yosemite

final class FilterProductListViewModel_numberOfActiveFiltersTests: XCTestCase {
    func testZeroActiveFilters() {
        let filters = FilterProductListViewModel.Filters()
        let filterTypeViewModels = createFilterTypeViewModels(filters: filters)
        XCTAssertEqual(filterTypeViewModels.numberOfActiveFilters, 0)
    }

    func testOneActiveFilter() {
        let filters = FilterProductListViewModel.Filters(stockStatus: nil,
                                                         productStatus: .draft,
                                                         promotableProductType: nil,
                                                         productCategory: nil,
                                                         numberOfActiveFilters: 0)
        let filterTypeViewModels = createFilterTypeViewModels(filters: filters)
        XCTAssertEqual(filterTypeViewModels.numberOfActiveFilters, 1)
    }

    func testTwoActiveFilters() {
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .published,
                                                         promotableProductType: nil,
                                                         productCategory: nil,
                                                         numberOfActiveFilters: 0)
        let filterTypeViewModels = createFilterTypeViewModels(filters: filters)
        XCTAssertEqual(filterTypeViewModels.numberOfActiveFilters, 2)
    }

    func testThreeActiveFilters() {
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .published,
                                                         promotableProductType: PromotableProductType(productType: .variable,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: nil,
                                                         numberOfActiveFilters: 0)
        let filterTypeViewModels = createFilterTypeViewModels(filters: filters)
        XCTAssertEqual(filterTypeViewModels.numberOfActiveFilters, 3)
    }

    func testFourActiveFilters() {
        let filterProductCategory = ProductCategory(categoryID: 0, siteID: 0, parentID: 0, name: "", slug: "")
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .published,
                                                         promotableProductType: PromotableProductType(productType: .variable,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: filterProductCategory,
                                                         numberOfActiveFilters: 0)
        let filterTypeViewModels = createFilterTypeViewModels(filters: filters)
        XCTAssertEqual(filterTypeViewModels.numberOfActiveFilters, 4)
    }
}

private extension FilterProductListViewModel_numberOfActiveFiltersTests {
    func createFilterTypeViewModels(filters: FilterProductListViewModel.Filters) -> [FilterTypeViewModel] {
        return [
            FilterProductListViewModel.ProductListFilter.stockStatus.createViewModel(filters: filters),
            FilterProductListViewModel.ProductListFilter.productStatus.createViewModel(filters: filters),
            FilterProductListViewModel.ProductListFilter.productType(siteID: 123).createViewModel(filters: filters),
            FilterProductListViewModel.ProductListFilter.productCategory(siteID: 0).createViewModel(filters: filters)
        ]
    }
}
