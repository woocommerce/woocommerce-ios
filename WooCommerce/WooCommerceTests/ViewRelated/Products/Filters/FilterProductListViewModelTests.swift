import XCTest
@testable import WooCommerce
@testable import Yosemite

final class FilterProductListViewModelTests: XCTestCase {
    let filterProductCategory = ProductCategory(categoryID: 0, siteID: 0, parentID: 0, name: "", slug: "")

    func testCriteriaWithDefaultFilters() {
        // Given
        let filters = FilterProductListViewModel.Filters()

        // When
        let viewModel = FilterProductListViewModel(filters: filters)

        // Then
        let expectedCriteria = FilterProductListViewModel.Filters(stockStatus: nil,
                                                                  productStatus: nil,
                                                                  productType: nil,
                                                                  productCategory: nil,
                                                                  numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func testCriteriaWithNonNilFilters() {
        // Given
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         productType: .grouped,
                                                         productCategory: filterProductCategory,
                                                         numberOfActiveFilters: 4)

        // When
        let featureFlagService = MockFeatureFlagService(isFilterProductsByCategoryOn: true)
        let viewModel = FilterProductListViewModel(filters: filters, featureFlagService: featureFlagService)

        // Then
        let expectedCriteria = filters
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func testCriteriaAfterClearingAllNonNilFilters() {
        // Given
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         productType: .grouped,
                                                         productCategory: filterProductCategory,
                                                         numberOfActiveFilters: 4)

        // When
        let featureFlagService = MockFeatureFlagService(isFilterProductsByCategoryOn: true)
        let viewModel = FilterProductListViewModel(filters: filters, featureFlagService: featureFlagService)
        viewModel.clearAll()

        // Then
        let expectedCriteria = FilterProductListViewModel.Filters(stockStatus: nil,
                                                                  productStatus: nil,
                                                                  productType: nil,
                                                                  productCategory: nil,
                                                                  numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func testCriteriaWithNonNilFiltersAndFilterProductByCategoryIsDisabled() {
        // Given
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         productType: .grouped,
                                                         productCategory: filterProductCategory,
                                                         numberOfActiveFilters: 4)

        // When
        let featureFlagService = MockFeatureFlagService(isFilterProductsByCategoryOn: false)
        let viewModel = FilterProductListViewModel(filters: filters, featureFlagService: featureFlagService)

        // Then
        let expectedCriteria = FilterProductListViewModel.Filters(stockStatus: filters.stockStatus,
                                                                  productStatus: filters.productStatus,
                                                                  productType: filters.productType,
                                                                  productCategory: nil,
                                                                  numberOfActiveFilters: 3)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func testViewModelsWhenFilterProductByCategoryIsDisabled() {
        // Given
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         productType: .grouped,
                                                         productCategory: filterProductCategory,
                                                         numberOfActiveFilters: 4)

        // When
        let featureFlagService = MockFeatureFlagService(isFilterProductsByCategoryOn: false)
        let viewModel = FilterProductListViewModel(filters: filters, featureFlagService: featureFlagService)

        // Then
        let productCategoryFilterTypeViewModels = viewModel.filterTypeViewModels.compactMap { $0.selectedValue as? ProductCategory }

        XCTAssertTrue(productCategoryFilterTypeViewModels.isEmpty)
        XCTAssertEqual(viewModel.filterTypeViewModels.count, 3)
    }
}
