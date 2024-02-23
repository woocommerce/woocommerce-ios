import XCTest
@testable import WooCommerce
@testable import Yosemite

final class FilterOrderListViewModelTests: XCTestCase {
    func test_criteria_with_default_filters() {
        // Given
        let filters = FilterOrderListViewModel.Filters()

        // When
        let viewModel = FilterOrderListViewModel(filters: filters, allowedStatuses: [], siteID: 1)

        // Then
        let expectedCriteria = FilterOrderListViewModel.Filters(orderStatus: nil,
                                                                dateRange: nil,
                                                                product: nil,
                                                                customer: nil,
                                                                numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func test_criteria_with_non_nil_filters() {
        // Given
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.processing],
                                                       dateRange: OrderDateRangeFilter(filter: .today),
                                                       product: FilterOrdersByProduct(id: 1, name: "Sample product"),
                                                       customer: CustomerFilter(id: 1),
                                                       numberOfActiveFilters: 4)

        // When
        let viewModel = FilterOrderListViewModel(filters: filters, allowedStatuses: [], siteID: 1)

        // Then
        let expectedCriteria = filters
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func test_criteria_after_clearing_all_non_nil_filters() {
        // Given
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.completed],
                                                       dateRange: OrderDateRangeFilter(filter: .last7Days),
                                                       product: ProductFilter(id: 1, name: "Sample product"),
                                                       customer: CustomerFilter(id: 1),
                                                       numberOfActiveFilters: 4)

        // When
        let viewModel = FilterOrderListViewModel(filters: filters, allowedStatuses: [], siteID: 1)
        viewModel.clearAll()

        // Then
        let expectedCriteria = FilterOrderListViewModel.Filters(orderStatus: nil,
                                                                dateRange: nil,
                                                                product: nil,
                                                                customer: nil,
                                                                numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    // MARK: Filter based on product

    func test_product_filter_is_not_added_to_filterTypeViewModels_when_feature_flag_off() {
        // Given
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.processing],
                                                       dateRange: OrderDateRangeFilter(filter: .today),
                                                       product: FilterOrdersByProduct(id: 1, name: "Sample product"),
                                                       numberOfActiveFilters: 3)

        // When
        let viewModel = FilterOrderListViewModel(filters: filters,
                                                 allowedStatuses: [],
                                                 siteID: 1,
                                                 featureFlagService: MockFeatureFlagService(filterOrdersByProduct: false))

        // Then
        XCTAssertFalse(viewModel.filterTypeViewModels.contains(where: {
            if case .products = $0.listSelectorConfig {
                return true
            } else {
                return false
            }}))
    }

    func test_product_filter_is_added_to_filterTypeViewModels_when_feature_flag_on() {
        // Given
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.processing],
                                                       dateRange: OrderDateRangeFilter(filter: .today),
                                                       product: FilterOrdersByProduct(id: 1, name: "Sample product"),
                                                       numberOfActiveFilters: 3)

        // When
        let viewModel = FilterOrderListViewModel(filters: filters,
                                                 allowedStatuses: [],
                                                 siteID: 1,
                                                 featureFlagService: MockFeatureFlagService(filterOrdersByProduct: true))

        // Then
        XCTAssertTrue(viewModel.filterTypeViewModels.contains(where: {
            if case .products = $0.listSelectorConfig {
                return true
            } else {
                return false
            }}))
    }
}
