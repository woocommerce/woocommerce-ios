import XCTest
import Yosemite
@testable import Storage
@testable import WooCommerce
import Combine

final class CustomerListViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 322

    private var subscriptions: [AnyCancellable] = []

    /// Mock Storage: InMemory
    private var storageManager: StorageManagerType!

    /// View storage for tests
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        subscriptions = []
        storageManager = MockStorageManager()
    }

    // MARK: - State transitions

    func test_state_is_empty_without_any_actions() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfSyncCustomers = 0
        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            guard case .synchronizeAllCustomers = action else {
                return
            }
            invocationCountOfSyncCustomers += 1
        }
        let viewModel = CustomersListViewModel(siteID: sampleSiteID, stores: stores)

        // Then
        XCTAssertEqual(viewModel.syncState, .empty)
        XCTAssertEqual(invocationCountOfSyncCustomers, 0)
    }

    func test_state_is_syncingFirstPage_and_synchronizeAllCustomers_is_dispatched_upon_loadCustomers() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfSyncCustomers = 0
        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            guard case .synchronizeAllCustomers = action else {
                return
            }
            invocationCountOfSyncCustomers += 1
        }
        let viewModel = CustomersListViewModel(siteID: sampleSiteID, stores: stores)

        // When
        viewModel.loadCustomers()

        // Then
        XCTAssertEqual(viewModel.syncState, .syncingFirstPage)
        XCTAssertEqual(invocationCountOfSyncCustomers, 1)
    }

    func test_state_is_syncingFirstPage_upon_loadCustomers_if_there_is_no_existing_customer_in_storage() {
        let viewModel = CustomersListViewModel(siteID: sampleSiteID)

        // When
        viewModel.loadCustomers()

        // Then
        XCTAssertEqual(viewModel.syncState, .syncingFirstPage)
    }

    func test_state_is_results_upon_loadCustomers_if_there_are_existing_customers_in_storage() {
        let existingCustomer = WCAnalyticsCustomer.fake().copy(siteID: sampleSiteID, customerID: 123)
        insertCustomers([existingCustomer])
        let viewModel = CustomersListViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.loadCustomers()

        // Then
        XCTAssertEqual(viewModel.syncState, .results)
    }

    func test_state_is_results_after_loadCustomers_with_nonempty_results() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let customer = WCAnalyticsCustomer.fake().copy(siteID: sampleSiteID)
        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            guard case let .synchronizeAllCustomers(_, _, _, completion) = action else {
                return
            }
            self.insertCustomers([customer])
            completion(.success(true))
        }
        let viewModel = CustomersListViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        var states = [CustomersListViewModel.SyncState]()
        viewModel.$syncState
            .removeDuplicates()
            .sink { state in
                states.append(state)
            }
            .store(in: &subscriptions)

        // When
        viewModel.loadCustomers()

        // Then
        XCTAssertEqual(states, [.empty, .syncingFirstPage, .results])
    }

    func test_state_is_back_to_empty_after_loadCustomers_with_empty_results() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfSyncCustomers = 0
        var syncPageNumber: Int?
        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            guard case let .synchronizeAllCustomers(_, pageNumber, _, completion) = action else {
                return
            }
            invocationCountOfSyncCustomers += 1
            syncPageNumber = pageNumber
            completion(.success(false))
        }
        let viewModel = CustomersListViewModel(siteID: sampleSiteID, stores: stores)

        var states = [CustomersListViewModel.SyncState]()
        viewModel.$syncState.sink { state in
            states.append(state)
        }.store(in: &subscriptions)

        // When
        viewModel.loadCustomers()

        // Then
        XCTAssertEqual(invocationCountOfSyncCustomers, 1)
        XCTAssertEqual(syncPageNumber, 1)
        XCTAssertEqual(states, [.empty, .syncingFirstPage, .empty])
    }

    func test_it_loads_next_page_after_loadCustomers_and_onLoadNextPageAction_until_hasNextPage_is_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfSyncCustomers = 0
        let firstPageItems = [Yosemite.WCAnalyticsCustomer](repeating: .fake().copy(siteID: sampleSiteID), count: 2)
        let secondPageItems = [Yosemite.WCAnalyticsCustomer](repeating: .fake().copy(siteID: sampleSiteID), count: 1)
        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            guard case let .synchronizeAllCustomers(_, pageNumber, _, completion) = action else {
                return
            }
            invocationCountOfSyncCustomers += 1
            let customers = pageNumber == 1 ? firstPageItems: secondPageItems
            self.insertCustomers(customers)
            completion(.success(pageNumber == 1 ? true : false))
        }

        let viewModel = CustomersListViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        var states = [CustomersListViewModel.SyncState]()
        viewModel.$syncState
            .removeDuplicates()
            .sink { state in
                states.append(state)
            }
            .store(in: &subscriptions)

        // When
        viewModel.loadCustomers()// Syncs first page of customers.
        viewModel.onLoadNextPageAction() // Syncs next page of customers.
        viewModel.onLoadNextPageAction() // No more data to be synced.

        // Then
        XCTAssertEqual(states, [.empty, .syncingFirstPage, .results])
        XCTAssertEqual(invocationCountOfSyncCustomers, 2)
    }

    // MARK: - Customer rows

    func test_customers_match_loaded_customers() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let customer = WCAnalyticsCustomer.fake().copy(siteID: sampleSiteID, name: "Customer")
        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            guard case let .synchronizeAllCustomers(_, _, _, completion) = action else {
                return
            }
            self.insertCustomers([customer])
            completion(.success(true))
        }
        let viewModel = CustomersListViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // When
        viewModel.loadCustomers()

        // Then
        XCTAssertEqual(viewModel.customers.first?.name, customer.name)
    }

    func test_customers_are_empty_when_loaded_customers_are_empty() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            guard case let .synchronizeAllCustomers(_, _, _, completion) = action else {
                return
            }
            completion(.success(false))
        }
        let viewModel = CustomersListViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // When
        viewModel.loadCustomers()

        // Then
        XCTAssertEqual(viewModel.customers.count, 0)
    }

    func test_customers_are_sorted_by_lastActiveDate() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let olderCustomer = WCAnalyticsCustomer.fake().copy(siteID: sampleSiteID, name: "Customer", dateLastActive: Date())
        let recentCustomer = WCAnalyticsCustomer.fake().copy(siteID: sampleSiteID, name: "Customer", dateLastActive: Date())
        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            guard case let .synchronizeAllCustomers(_, _, _, completion) = action else {
                return
            }
            let items = [olderCustomer, recentCustomer]
            self.insertCustomers(items)
            completion(.success(false))
        }
        let viewModel = CustomersListViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // When
        viewModel.loadCustomers()

        // Then customers are first sorted by descending dateLastActive
        XCTAssertEqual(viewModel.customers.count, 2)
        assertEqual(viewModel.customers[0].name, recentCustomer.name)
        assertEqual(viewModel.customers[1].name, olderCustomer.name)
    }

    // MARK: - `onRefreshAction`

    func test_onRefreshAction_resyncs_the_first_page() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var invocationCountOfSyncCustomers = 0
        stores.whenReceivingAction(ofType: CustomerAction.self) { action in
            guard case let .synchronizeAllCustomers(_, _, _, onCompletion) = action else {
                return
            }
            invocationCountOfSyncCustomers += 1
            onCompletion(.success(false))
        }
        let viewModel = CustomersListViewModel(siteID: sampleSiteID, stores: stores)

        // When
        waitFor { promise in
            viewModel.onRefreshAction {
                promise(())
            }
        }

        // Then
        XCTAssertEqual(invocationCountOfSyncCustomers, 1)
    }

    // MARK: - Search

    func test_searchTerm_is_clear_and_filter_is_set_to_default_on_init() {
        // Given
        let viewModel = CustomersListViewModel(siteID: sampleSiteID)

        // Then
        XCTAssertEqual(viewModel.searchTerm, "")
        XCTAssertEqual(viewModel.searchFilter, .name)
    }

    func test_filter_is_updated_and_advanced_search_shows_when_store_is_eligible() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var viewModel: CustomersListViewModel?

        // When
        _ = waitFor { promise in
            stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
                guard case let .fetchSystemPlugin(_, _, completion) = action else {
                    return
                }
                completion(SystemPlugin.fake().copy(name: "WooCommerce", version: "8.0.0", active: true))
                promise(true)
            }
            viewModel = CustomersListViewModel(siteID: self.sampleSiteID, stores: stores)
        }

        // Then
        assertEqual(true, viewModel?.showAdvancedSearch)
        assertEqual(.all, viewModel?.searchFilter)
    }

    func test_search_includes_searchTerm_and_selected_filter() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var searchKeyword: String?
        var searchFilter: CustomerSearchFilter?
        let viewModel = CustomersListViewModel(siteID: sampleSiteID, stores: stores)

        // When
        _ = waitFor { promise in
            stores.whenReceivingAction(ofType: CustomerAction.self) { action in
                guard case let .searchWCAnalyticsCustomers(_, _, _, keyword, filter, completion) = action else {
                    return
                }
                searchKeyword = keyword
                searchFilter = filter
                promise(true)
            }
            viewModel.searchTerm = "search"
            viewModel.searchFilter = .username
        }

        // Then
        assertEqual(viewModel.searchTerm, searchKeyword)
        assertEqual(viewModel.searchFilter, searchFilter)
    }

    func test_state_is_syncingFirstPage_and_searchWCAnalyticsCustomers_is_dispatched_when_searchTerm_is_set() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = CustomersListViewModel(siteID: sampleSiteID, stores: stores)

        // When
        let searchState: CustomersListViewModel.SyncState? = waitFor { promise in
            stores.whenReceivingAction(ofType: CustomerAction.self) { action in
                guard case .searchWCAnalyticsCustomers = action else {
                    return
                }
                promise(viewModel.syncState)
            }
            viewModel.searchTerm = "search"
        }

        // Then
        assertEqual(.syncingFirstPage, searchState)
    }

    func test_state_reset_to_empty_when_search_returns_no_results() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = CustomersListViewModel(siteID: sampleSiteID, stores: stores)

        // When
        let searchComplete: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: CustomerAction.self) { action in
                guard case let .searchWCAnalyticsCustomers(_, _, _, _, _, completion) = action else {
                    return
                }
                completion(.success(false))
                promise(true)
            }
            viewModel.searchTerm = "search"
        }

        // Then
        XCTAssertTrue(searchComplete)
        assertEqual(.empty, viewModel.syncState)
    }

    func test_customers_updated_with_search_results() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = CustomersListViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // When
        _ = waitFor { promise in
            stores.whenReceivingAction(ofType: CustomerAction.self) { action in
                guard case let .searchWCAnalyticsCustomers(_, _, _, keyword, _, completion) = action else {
                    return
                }
                self.insert([WCAnalyticsCustomer.fake().copy(siteID: self.sampleSiteID, name: "Pat")], withSearchTerm: keyword)
                completion(.success(false))
                promise(true)
            }
            viewModel.searchTerm = "Pat"
        }

        // Then
        assertEqual(.results, viewModel.syncState)
        assertEqual(1, viewModel.customers.count)
    }

}

private extension CustomerListViewModelTests {
    func insertCustomers(_ readOnlyCustomers: [Yosemite.WCAnalyticsCustomer]) {
        readOnlyCustomers.forEach { customer in
            let newCustomer = storage.insertNewObject(ofType: StorageWCAnalyticsCustomer.self)
            newCustomer.update(with: customer)
        }
        storage.saveIfNeeded()
    }

    func insert(_ readOnlyCustomers: [Yosemite.WCAnalyticsCustomer], withSearchTerm keyword: String) {
        insertCustomers(readOnlyCustomers)

        readOnlyCustomers.forEach { customer in
            let searchResult = storage.insertNewObject(ofType: WCAnalyticsCustomerSearchResult.self)
            searchResult.siteID = sampleSiteID
            searchResult.keyword = keyword

            if let storedCustomer = storage.loadWCAnalyticsCustomer(siteID: customer.siteID, customerID: customer.customerID) {
                searchResult.addToCustomers(storedCustomer)
            }
        }
    }
}
