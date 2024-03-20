import XCTest
import Yosemite
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
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
        let firstPageItems = [WCAnalyticsCustomer](repeating: .fake().copy(siteID: sampleSiteID), count: 2)
        let secondPageItems = [WCAnalyticsCustomer](repeating: .fake().copy(siteID: sampleSiteID), count: 1)
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

}

private extension CustomerListViewModelTests {
    func insertCustomers(_ readOnlyCustomers: [WCAnalyticsCustomer]) {
        readOnlyCustomers.forEach { customer in
            let newCustomer = storage.insertNewObject(ofType: StorageWCAnalyticsCustomer.self)
            newCustomer.update(with: customer)
        }
        storage.saveIfNeeded()
    }
}
