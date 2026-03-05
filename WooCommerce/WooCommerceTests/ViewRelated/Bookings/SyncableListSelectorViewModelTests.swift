import Combine
import Foundation
import Testing
import Yosemite
import class Storage.ProductSearchResults
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
struct SyncableListSelectorViewModelTests {

    private let sampleSiteID: Int64 = 123

    /// Mock Storage: InMemory
    private var storageManager: StorageManagerType

    /// View storage for tests
    private var storage: StorageType {
        storageManager.viewStorage
    }

    init() {
        storageManager = MockStorageManager()
    }

    // MARK: - Initialization

    @Test func initial_state_is_empty() {
        // Given
        let syncable = MockListSyncable(siteID: sampleSiteID)
        let stores = MockStoresManager(sessionManager: .testingInstance)

        // When
        let viewModel = SyncableListSelectorViewModel(syncable: syncable, stores: stores, storage: storageManager)

        // Then
        #expect(viewModel.syncState == .empty)
        #expect(viewModel.items.isEmpty)
        #expect(viewModel.searchQuery.isEmpty)
        #expect(viewModel.shouldShowBottomActivityIndicator == false)
    }

    // MARK: - State transitions

    @Test func state_transitions_to_syncing_first_page_on_load_resources() {
        // Given
        let syncable = MockListSyncable(siteID: sampleSiteID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = SyncableListSelectorViewModel(syncable: syncable, stores: stores, storage: storageManager)

        // When
        viewModel.loadResources()

        // Then
        #expect(viewModel.syncState == .syncingFirstPage)
        #expect(viewModel.shouldShowBottomActivityIndicator == true)
    }

    @Test func state_transitions_to_results_after_successful_sync_with_data() async {
        // Given
        let syncable = MockListSyncable(siteID: sampleSiteID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let product = Product.fake().copy(siteID: sampleSiteID, productID: 1, productTypeKey: ProductType.booking.rawValue)

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, _, onCompletion) = action else {
                return
            }
            self.insertProducts([product])
            onCompletion(.success(true))
        }

        let viewModel = SyncableListSelectorViewModel(syncable: syncable, stores: stores, storage: storageManager)

        var states = [SyncableListSelectorViewModel<MockListSyncable>.SyncState]()
        await confirmation("State transitions") { confirmation in
            var subscriptions: [AnyCancellable] = []
            var expectedStateCount = 0
            viewModel.$syncState
                .removeDuplicates()
                .sink { state in
                    states.append(state)
                    expectedStateCount += 1
                    if expectedStateCount >= 3 {
                        confirmation()
                    }
                }
                .store(in: &subscriptions)

            // When
            viewModel.loadResources()
        }

        // Then
        #expect(states == [.empty, .syncingFirstPage, .results])
        #expect(viewModel.items.count == 1)
        #expect(viewModel.shouldShowBottomActivityIndicator == false)
    }

    @Test func state_transitions_to_empty_after_successful_sync_with_no_data() async {
        // Given
        let syncable = MockListSyncable(siteID: sampleSiteID)
        let stores = MockStoresManager(sessionManager: .testingInstance)

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, _, onCompletion) = action else {
                return
            }
            onCompletion(.success(false))
        }

        let viewModel = SyncableListSelectorViewModel(syncable: syncable, stores: stores, storage: storageManager)

        var states = [SyncableListSelectorViewModel<MockListSyncable>.SyncState]()
        await confirmation("State transitions") { confirmation in
            var subscriptions: [AnyCancellable] = []
            var expectedStateCount = 0
            viewModel.$syncState
                .removeDuplicates()
                .sink { state in
                    states.append(state)
                    expectedStateCount += 1
                    if expectedStateCount >= 3 {
                        confirmation()
                    }
                }
                .store(in: &subscriptions)

            // When
            viewModel.loadResources()
        }

        // Then
        #expect(states == [.empty, .syncingFirstPage, .empty])
        #expect(viewModel.items.isEmpty)
    }

    // MARK: - Pagination

    @Test func sync_action_is_dispatched_on_load_resources() {
        // Given
        let syncable = MockListSyncable(siteID: sampleSiteID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var syncActionCalled = false

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case .synchronizeProducts = action else {
                return
            }
            syncActionCalled = true
        }

        let viewModel = SyncableListSelectorViewModel(syncable: syncable, stores: stores, storage: storageManager)

        // When
        viewModel.loadResources()

        // Then
        #expect(syncActionCalled)
    }

    @Test func next_page_is_loaded_on_load_next_page_action() async {
        // Given
        let syncable = MockListSyncable(siteID: sampleSiteID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var syncCallCount = 0
        let firstPageProducts = [Product.fake().copy(siteID: sampleSiteID, productID: 1, productTypeKey: ProductType.booking.rawValue)]
        let secondPageProducts = [Product.fake().copy(siteID: sampleSiteID, productID: 2, productTypeKey: ProductType.booking.rawValue)]

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .synchronizeProducts(_, pageNumber, _, _, _, _, _, _, _, _, _, onCompletion) = action else {
                return
            }
            syncCallCount += 1
            let products = pageNumber == 1 ? firstPageProducts : secondPageProducts
            self.insertProducts(products)
            onCompletion(.success(pageNumber == 1))
        }

        let viewModel = SyncableListSelectorViewModel(syncable: syncable, stores: stores, storage: storageManager)

        await confirmation("Pagination") { confirmation in
            var subscriptions: [AnyCancellable] = []
            viewModel.$items
                .dropFirst() // Skip initial empty state
                .removeDuplicates()
                .sink { items in
                    if items.count >= 2 {
                        confirmation()
                    }
                }
                .store(in: &subscriptions)

            // When
            viewModel.loadResources() // Load first page
            viewModel.onLoadNextPageAction() // Load second page
        }

        // Then
        #expect(syncCallCount == 2)
        #expect(viewModel.items.count == 2)
    }

    // MARK: - Search functionality

    @Test func search_action_is_dispatched_when_search_query_changes() async {
        // Given
        let syncable = MockListSyncable(siteID: sampleSiteID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var searchActionCalled = false
        var capturedKeyword: String?

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .searchProducts(_, keyword, _, _, _, _, _, _, _, _, onCompletion) = action else {
                return
            }
            searchActionCalled = true
            capturedKeyword = keyword
            onCompletion(.success(false))
        }

        let viewModel = SyncableListSelectorViewModel(syncable: syncable, stores: stores, storage: storageManager)

        // When
        viewModel.searchQuery = "test"

        // Wait for debounce
        try? await Task.sleep(nanoseconds: 400_000_000) // 400ms

        // Then
        #expect(searchActionCalled)
        #expect(capturedKeyword == "test")
    }

    @Test func search_predicate_is_applied_when_search_query_is_not_empty() async {
        // Given
        let syncable = MockListSyncable(siteID: sampleSiteID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let searchKeyword = "booking"
        let matchingProduct = Product.fake().copy(
            siteID: sampleSiteID,
            productID: 1,
            name: "Booking Service",
            productTypeKey: ProductType.booking.rawValue
        )
        let nonMatchingProduct = Product.fake().copy(
            siteID: sampleSiteID,
            productID: 2,
            name: "Other Service",
            productTypeKey: ProductType.booking.rawValue
        )

        // Insert products with search results
        insertProducts([matchingProduct, nonMatchingProduct])
        addSearchResult(for: matchingProduct, keyword: searchKeyword)

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .searchProducts(_, _, _, _, _, _, _, _, _, _, onCompletion) = action else {
                return
            }
            onCompletion(.success(false))
        }

        let viewModel = SyncableListSelectorViewModel(syncable: syncable, stores: stores, storage: storageManager)

        // Initially should have 2 products
        #expect(viewModel.items.count == 2)

        // When
        viewModel.searchQuery = searchKeyword

        // Wait for debounce and sync to complete
        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms

        // Then - should only show products matching the search
        #expect(viewModel.items.count == 1)
        #expect(viewModel.items.first?.productID == matchingProduct.productID)
    }

    @Test func search_predicate_is_removed_when_search_query_is_cleared() async {
        // Given
        let syncable = MockListSyncable(siteID: sampleSiteID)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, productTypeKey: ProductType.booking.rawValue)
        let product2 = Product.fake().copy(siteID: sampleSiteID, productID: 2, productTypeKey: ProductType.booking.rawValue)

        insertProducts([product1, product2])
        addSearchResult(for: product1, keyword: "test")

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .searchProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                onCompletion(.success(false))
            case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, _, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        let viewModel = SyncableListSelectorViewModel(syncable: syncable, stores: stores, storage: storageManager)

        // Set search query
        viewModel.searchQuery = "test"
        try? await Task.sleep(nanoseconds: 400_000_000)

        #expect(viewModel.items.count == 1)

        // When - clear search query
        viewModel.searchQuery = ""
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then - should show all products
        #expect(viewModel.items.count == 2)
    }

    @Test func syncable_without_search_predicate_uses_base_predicate_during_search() async {
        // Given
        let syncable = MockListSyncable(siteID: sampleSiteID, hasSearchPredicate: false)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        var searchActionCalled = false

        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, productTypeKey: ProductType.booking.rawValue)
        let product2 = Product.fake().copy(siteID: sampleSiteID, productID: 2, productTypeKey: ProductType.booking.rawValue)
        insertProducts([product1, product2])

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .searchProducts(_, _, _, _, _, _, _, _, _, _, onCompletion):
                searchActionCalled = true
                onCompletion(.success(false))
            case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, _, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        let viewModel = SyncableListSelectorViewModel(syncable: syncable, stores: stores, storage: storageManager)

        // When
        viewModel.searchQuery = "test"

        // Wait for debounce
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then - search action should be called but predicate remains unchanged
        #expect(searchActionCalled)
        #expect(viewModel.items.count == 2)
    }

    // MARK: - Error handling

    @Test func state_transitions_to_empty_on_sync_error() async {
        // Given
        let syncable = MockListSyncable(siteID: sampleSiteID)
        let stores = MockStoresManager(sessionManager: .testingInstance)

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .synchronizeProducts(_, _, _, _, _, _, _, _, _, _, _, onCompletion) = action else {
                return
            }
            onCompletion(.failure(NSError(domain: "test", code: 1)))
        }

        let viewModel = SyncableListSelectorViewModel(syncable: syncable, stores: stores, storage: storageManager)

        var states = [SyncableListSelectorViewModel<MockListSyncable>.SyncState]()
        await confirmation("Error state transition") { confirmation in
            var subscriptions: [AnyCancellable] = []
            var expectedStateCount = 0
            viewModel.$syncState
                .removeDuplicates()
                .sink { state in
                    states.append(state)
                    expectedStateCount += 1
                    if expectedStateCount >= 3 {
                        confirmation()
                    }
                }
                .store(in: &subscriptions)

            // When
            viewModel.loadResources()
        }

        // Then
        #expect(states == [.empty, .syncingFirstPage, .empty])
        #expect(viewModel.shouldShowBottomActivityIndicator == false)
    }
}

// MARK: - Test Helpers

private extension SyncableListSelectorViewModelTests {
    func insertProducts(_ products: [Product]) {
        storageManager.performAndSave({ storage in
            products.forEach { product in
                let storageProduct = storage.insertNewObject(ofType: StorageProduct.self)
                storageProduct.update(with: product)
            }
        }, completion: {}, on: .main)
    }

    func addSearchResult(for product: Product, keyword: String) {
        storageManager.performAndSave({ storage in
            guard let storageProduct = storage.loadProduct(siteID: product.siteID, productID: product.productID) else {
                return
            }
            let searchResult = storage.insertNewObject(ofType: ProductSearchResults.self)
            searchResult.keyword = keyword
            searchResult.filterKey = ProductSearchFilter.all.rawValue
            searchResult.addToProducts(storageProduct)
        }, completion: {}, on: .main)
    }
}

// MARK: - Mock Syncable

private struct MockListSyncable: ListSyncable {
    typealias StorageType = StorageProduct
    typealias ModelType = Product
    typealias ListFilterType = BookingProductFilter

    let siteID: Int64
    let title = "Test Products"
    let emptyStateMessage = "No products found"
    let emptyItemTitlePlaceholder: String? = nil
    let searchConfiguration: ListSearchConfiguration? = nil
    let selectionDisabledMessage: String? = nil

    private let hasSearchPredicate: Bool

    init(siteID: Int64, hasSearchPredicate: Bool = true) {
        self.siteID = siteID
        self.hasSearchPredicate = hasSearchPredicate
    }

    func createPredicate() -> NSPredicate {
        NSPredicate(format: "siteID == %lld AND productTypeKey == %@", siteID, ProductType.booking.rawValue)
    }

    func createSortDescriptors() -> [NSSortDescriptor] {
        [NSSortDescriptor(key: "productID", ascending: false)]
    }

    func createSyncAction(pageNumber: Int, pageSize: Int, completion: @escaping (Result<Bool, Error>) -> Void) -> Action {
        ProductAction.synchronizeProducts(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            stockStatus: nil,
            productStatus: nil,
            productType: .booking,
            productCategory: nil,
            sortOrder: .dateDescending,
            shouldDeleteStoredProductsOnFirstPage: true,
            onCompletion: completion
        )
    }

    func createSearchAction(keyword: String, pageNumber: Int, pageSize: Int, completion: @escaping (Result<Bool, Error>) -> Void) -> Action {
        ProductAction.searchProducts(
            siteID: siteID,
            keyword: keyword,
            pageNumber: pageNumber,
            pageSize: pageSize,
            productType: .booking,
            onCompletion: completion
        )
    }

    func createSearchPredicate(keyword: String) -> NSPredicate? {
        hasSearchPredicate ? NSPredicate(format: "SUBQUERY(searchResults, $result, $result.keyword = %@).@count > 0", keyword) : nil
    }

    func displayName(for item: Product) -> String { item.name }

    func description(for item: Product) -> String? { nil }

    func selectionEnabled(for item: Product) -> Bool { true }

    func filterItem(for item: Product) -> BookingProductFilter {
        BookingProductFilter(productID: item.productID, name: item.name)
    }
}
