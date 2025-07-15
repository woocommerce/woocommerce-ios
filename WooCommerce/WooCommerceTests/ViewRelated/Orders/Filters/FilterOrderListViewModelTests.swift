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
                                                                salesChannel: nil,
                                                                numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func test_criteria_with_non_nil_filters() {
        // Given
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.processing],
                                                       dateRange: OrderDateRangeFilter(filter: .today),
                                                       product: FilterOrdersByProduct(id: 1, name: "Sample product"),
                                                       customer: CustomerFilter(customer: Customer.fake().copy(customerID: 1)),
                                                       salesChannel: .pointOfSale,
                                                       numberOfActiveFilters: 5)

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
                                                       product: FilterOrdersByProduct(id: 1, name: "Sample product"),
                                                       customer: CustomerFilter(customer: Customer.fake().copy(customerID: 1)),
                                                       salesChannel: .pointOfSale,
                                                       numberOfActiveFilters: 5)

        // When
        let viewModel = FilterOrderListViewModel(filters: filters, allowedStatuses: [], siteID: 1)
        viewModel.clearAll()

        // Then
        let expectedCriteria = FilterOrderListViewModel.Filters(orderStatus: nil,
                                                                dateRange: nil,
                                                                product: nil,
                                                                customer: nil,
                                                                salesChannel: nil,
                                                                numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    // MARK: Filter based on product

    func test_product_filter_is_added_to_filterTypeViewModels() {
        // Given
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.processing],
                                                       dateRange: OrderDateRangeFilter(filter: .today),
                                                       product: FilterOrdersByProduct(id: 1, name: "Sample product"),
                                                       customer: CustomerFilter(customer: Customer.fake().copy(customerID: 1)),
                                                       salesChannel: .pointOfSale,
                                                       numberOfActiveFilters: 5)

        // When
        let viewModel = FilterOrderListViewModel(filters: filters,
                                                 allowedStatuses: [],
                                                 siteID: 1)

        // Then
        XCTAssertTrue(viewModel.filterTypeViewModels.contains(where: {
            if case .products = $0.listSelectorConfig {
                return true
            } else {
                return false
            }}))
    }

    @MainActor
    func test_retrieveFilterHistory_returns_correct_results() async throws {
        // Given
        let siteID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let result1 = createMockFilter(siteID: siteID, orderStatuses: [.pending])
        let result2 = createMockFilter(siteID: siteID, orderStatuses: [.completed])
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadOrderFilterHistory(_, onCompletion):
                onCompletion(.success([result1, result2]))
            default:
                break
            }
        }

        let filters = FilterOrderListViewModel.Filters(orderStatus: [.processing],
                                                       dateRange: OrderDateRangeFilter(filter: .today),
                                                       product: FilterOrdersByProduct(id: 1, name: "Sample product"),
                                                       customer: CustomerFilter(customer: Customer.fake().copy(customerID: 1)),
                                                       salesChannel: SalesChannelFilter.pointOfSale,
                                                       numberOfActiveFilters: 5)
        let viewModel = FilterOrderListViewModel(filters: filters,
                                                 allowedStatuses: [],
                                                 siteID: siteID,
                                                 stores: stores)

        // When
        let history = try await viewModel.retrieveFilterHistory()

        // Then
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history, [
            FilterOrderListViewModel.Filters(orderStatus: result1.orderStatusesFilter,
                                             dateRange: result1.dateRangeFilter,
                                             product: result1.productFilter,
                                             customer: result1.customerFilter,
                                             salesChannel: result1.salesChannelFilter,
                                             numberOfActiveFilters: result1.numberOfActiveFilters()),
            FilterOrderListViewModel.Filters(orderStatus: result2.orderStatusesFilter,
                                             dateRange: result2.dateRangeFilter,
                                             product: result2.productFilter,
                                             customer: result2.customerFilter,
                                             salesChannel: result2.salesChannelFilter,
                                             numberOfActiveFilters: result2.numberOfActiveFilters())
        ])
    }

    func test_saveSelectedFilterToHistory_updates_filter_history_with_the_new_filter() {
        // Given
        let siteID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var savedSettings: StoredOrderSettings.Setting?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .upsertOrderFilterHistory(filter, onCompletion):
                savedSettings = filter
                onCompletion(nil)
            default:
                break
            }
        }

        let filters = FilterOrderListViewModel.Filters(orderStatus: [.processing],
                                                       dateRange: OrderDateRangeFilter(filter: .today),
                                                       product: FilterOrdersByProduct(id: 1, name: "Sample product"),
                                                       customer: CustomerFilter(customer: Customer.fake().copy(customerID: 1)),
                                                       salesChannel: nil,
                                                       numberOfActiveFilters: 4)
        let viewModel = FilterOrderListViewModel(filters: filters,
                                                 allowedStatuses: [],
                                                 siteID: siteID,
                                                 stores: stores)

        // When
        viewModel.saveSelectedFilterToHistory(filters)

        // Then
        XCTAssertEqual(savedSettings?.siteID, siteID)
        XCTAssertEqual(savedSettings?.customerFilter, filters.customer)
        XCTAssertEqual(savedSettings?.productFilter, filters.product)
        XCTAssertEqual(savedSettings?.dateRangeFilter, filters.dateRange)
    }

    func test_removeFilterFromHistory_removes_the_correct_filter() {
        // Given
        let siteID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var removedSettings: StoredOrderSettings.Setting?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .removeFromOrderFilterHistory(filter, onCompletion):
                removedSettings = filter
                onCompletion(nil)
            default:
                break
            }
        }

        let filters = FilterOrderListViewModel.Filters(orderStatus: [.processing],
                                                       dateRange: OrderDateRangeFilter(filter: .today),
                                                       product: FilterOrdersByProduct(id: 1, name: "Sample product"),
                                                       customer: CustomerFilter(customer: Customer.fake().copy(customerID: 1)),
                                                       salesChannel: nil,
                                                       numberOfActiveFilters: 4)
        let viewModel = FilterOrderListViewModel(filters: filters,
                                                 allowedStatuses: [],
                                                 siteID: siteID,
                                                 stores: stores)

        // When
        viewModel.removeFilterFromHistory(filters)

        // Then
        XCTAssertEqual(removedSettings?.siteID, siteID)
        XCTAssertEqual(removedSettings?.customerFilter, filters.customer)
        XCTAssertEqual(removedSettings?.productFilter, filters.product)
        XCTAssertEqual(removedSettings?.dateRangeFilter, filters.dateRange)
    }
}

private extension FilterOrderListViewModelTests {
    func createMockFilter(siteID: Int64,
                          orderStatuses: [OrderStatusEnum] = [.pending, .completed]) -> StoredOrderSettings.Setting {
        let orderStatuses = orderStatuses
        let startDate = Date().yearStart
        let endDate = Date().yearEnd
        let dateRange = OrderDateRangeFilter(filter: .custom, startDate: startDate, endDate: endDate)
        let productFilter = FilterOrdersByProduct(id: 1, name: "Sample product")
        let customerFilter = CustomerFilter(customer: Customer.fake().copy(customerID: 1))
        let salesChannelFilter = SalesChannelFilter.pointOfSale
        return StoredOrderSettings.Setting(siteID: siteID,
                                           orderStatusesFilter: orderStatuses,
                                           dateRangeFilter: dateRange,
                                           productFilter: productFilter,
                                           customerFilter: customerFilter,
                                           salesChannelFilter: salesChannelFilter)
    }
}
