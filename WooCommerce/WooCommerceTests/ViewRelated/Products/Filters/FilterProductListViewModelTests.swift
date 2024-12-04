import XCTest
@testable import WooCommerce
@testable import Yosemite

final class FilterProductListViewModelTests: XCTestCase {
    let filterProductCategory = ProductCategory(categoryID: 0, siteID: 0, parentID: 0, name: "", slug: "category")

    func testCriteriaWithDefaultFilters() {
        // Given
        let filters = FilterProductListViewModel.Filters()

        // When
        let viewModel = FilterProductListViewModel(filters: filters, siteID: 0)

        // Then
        let expectedCriteria = FilterProductListViewModel.Filters(stockStatus: nil,
                                                                  productStatus: nil,
                                                                  promotableProductType: nil,
                                                                  productCategory: nil,
                                                                  favoriteProduct: nil,
                                                                  numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func test_criteria_with_non_nil_filters_then_it_returns_all_active_filters() {
        // Given
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         promotableProductType: PromotableProductType(productType: .grouped,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: filterProductCategory,
                                                         favoriteProduct: FavoriteProductsFilter(),
                                                         numberOfActiveFilters: 5)

        // When
        let viewModel = FilterProductListViewModel(filters: filters,
                                                   siteID: 0)

        // Then
        let expectedCriteria = filters
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func test_criteria_after_clearing_all_non_nil_filters_then_it_returns_no_active_filter() {
        // Given
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         promotableProductType: PromotableProductType(productType: .grouped,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: filterProductCategory,
                                                         favoriteProduct: FavoriteProductsFilter(),
                                                         numberOfActiveFilters: 5)

        // When
        let viewModel = FilterProductListViewModel(filters: filters, siteID: 0)
        viewModel.clearAll()

        // Then
        let expectedCriteria = FilterProductListViewModel.Filters(stockStatus: nil,
                                                                  productStatus: nil,
                                                                  promotableProductType: nil,
                                                                  productCategory: nil,
                                                                  favoriteProduct: nil,
                                                                  numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func test_it_provides_analytics_description_based_on_selected_filters() {
        // Given
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         promotableProductType: PromotableProductType(productType: .grouped,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: filterProductCategory,
                                                         favoriteProduct: FavoriteProductsFilter(),
                                                         numberOfActiveFilters: 5)

        // Then
        XCTAssertEqual(filters.analyticsDescription, "instock,draft,grouped,category,favorite_products")
    }
}
