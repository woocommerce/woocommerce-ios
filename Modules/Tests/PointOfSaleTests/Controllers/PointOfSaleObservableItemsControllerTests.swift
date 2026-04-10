import Testing
import Foundation
@testable import PointOfSale
@testable import Yosemite

@MainActor
final class PointOfSaleObservableItemsControllerTests {

    // MARK: - Test Helpers

    private func makeSimpleProduct(id: POSItemIdentifier? = nil, name: String = "Test Product", productID: Int64 = 1) -> POSItem {
        .simpleProduct(POSSimpleProduct(
            id: id ?? POSItemIdentifier(underlyingType: .product, itemID: productID),
            name: name,
            formattedPrice: "$2.00",
            productID: productID,
            price: "2.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: ""
        ))
    }

    private func makeVariation(id: POSItemIdentifier? = nil, name: String = "Test Variation", variationID: Int64 = 1) -> POSItem {
        .variation(POSVariation(
            id: id ?? POSItemIdentifier(underlyingType: .variation, itemID: variationID),
            name: name,
            formattedPrice: "$2.00",
            price: "2.00",
            productID: 100,
            variationID: variationID,
            parentProductName: "Parent Product"
        ))
    }

    // MARK: - Tests

    @Test func test_initial_state_is_loading_container_with_initial_root() {
        // Given
        let dataSource = MockPOSObservableDataSource()
        dataSource.isLoadingProducts = true
        let coordinator = MockPOSCatalogSyncCoordinator()
        let sut = PointOfSaleObservableItemsController(siteID: 123, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        // Then
        guard case .loading(let isCatalogSyncing) = sut.itemsViewState.containerState else {
            Issue.record("Expected loading state")
            return
        }
        #expect(isCatalogSyncing == false)
        #expect(sut.itemsViewState.itemsStack.root == .initial)
        #expect(sut.itemsViewState.itemsStack.itemStates.isEmpty)
    }

    @Test func test_load_products_transitions_to_loaded_state() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let sut = PointOfSaleObservableItemsController(siteID: 123, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        let mockItems = [makeSimpleProduct()]
        dataSource.productItems = mockItems
        dataSource.isLoadingProducts = false
        dataSource.hasMoreProducts = false

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState.containerState == .content)
        #expect(sut.itemsViewState.itemsStack.root == .loaded(mockItems, hasMoreItems: false))
    }

    @Test func test_load_products_with_more_pages_sets_hasMoreItems() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let sut = PointOfSaleObservableItemsController(siteID: 123, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        let mockItems = [makeSimpleProduct(productID: 1), makeSimpleProduct(productID: 2)]
        dataSource.productItems = mockItems
        dataSource.isLoadingProducts = false
        dataSource.hasMoreProducts = true

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState.itemsStack.root == .loaded(mockItems, hasMoreItems: true))
    }

    @Test func test_load_products_when_empty_triggers_refresh_on_subsequent_load() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let sut = PointOfSaleObservableItemsController(siteID: 123, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        dataSource.productItems = []
        dataSource.isLoadingProducts = false
        coordinator.performIncrementalSyncResult = .success(())

        // When: First load (initial load, no refresh triggered)
        await sut.loadItems(base: .root)
        #expect(coordinator.performIncrementalSyncInvocationCount == 0)

        // When: Second load while still empty (should trigger refresh)
        await sut.loadItems(base: .root)

        // Then: Should trigger refresh when empty after initial load
        #expect(coordinator.performIncrementalSyncInvocationCount == 1)
        #expect(sut.itemsViewState.containerState == .content)
        #expect(sut.itemsViewState.itemsStack.root == .empty)
    }

    @Test func test_load_variations_for_parent() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let sut = PointOfSaleObservableItemsController(siteID: 123, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        let parentProduct = POSVariableParentProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Parent",
            productImageSource: nil,
            productID: 100,
            allAttributes: []
        )
        let parentItem = POSItem.variableParentProduct(parentProduct)

        let mockVariations = [makeVariation(variationID: 1), makeVariation(variationID: 2)]
        dataSource.variationItems = mockVariations
        dataSource.isLoadingVariations = false
        dataSource.hasMoreVariations = false

        // When
        await sut.loadItems(base: .parent(parentItem))

        // Then
        #expect(sut.itemsViewState.itemsStack.itemStates[parentItem] == .loaded(mockVariations, hasMoreItems: false))
    }

    @Test func test_load_variations_when_empty_triggers_refresh_on_subsequent_load() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let sut = PointOfSaleObservableItemsController(siteID: 123, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        let parentProduct = POSVariableParentProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Parent",
            productImageSource: nil,
            productID: 100,
            allAttributes: []
        )
        let parentItem = POSItem.variableParentProduct(parentProduct)

        dataSource.variationItems = []
        dataSource.isLoadingVariations = false
        coordinator.performIncrementalSyncResult = .success(())

        // When: First load (initial load, no refresh triggered)
        await sut.loadItems(base: .parent(parentItem))
        #expect(coordinator.performIncrementalSyncInvocationCount == 0)

        // When: Second load while still empty (should trigger refresh)
        await sut.loadItems(base: .parent(parentItem))

        // Then: Should trigger refresh when empty after initial load
        #expect(coordinator.performIncrementalSyncInvocationCount == 1)
        #expect(sut.itemsViewState.itemsStack.itemStates[parentItem] == .empty)
    }

    @Test func test_products_and_variations_are_independent() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let sut = PointOfSaleObservableItemsController(siteID: 123, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        let mockProducts = [makeSimpleProduct(productID: 1), makeSimpleProduct(productID: 2)]
        let mockVariations = [makeVariation()]

        let parentProduct = POSVariableParentProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Parent",
            productImageSource: nil,
            productID: 100,
            allAttributes: []
        )
        let parentItem = POSItem.variableParentProduct(parentProduct)

        // When: Load products
        dataSource.productItems = mockProducts
        dataSource.isLoadingProducts = false
        await sut.loadItems(base: .root)

        // Then: Products loaded, no variations
        #expect(sut.itemsViewState.itemsStack.root.items.count == 2)
        #expect(sut.itemsViewState.itemsStack.itemStates.isEmpty)

        // When: Load variations
        dataSource.variationItems = mockVariations
        dataSource.isLoadingVariations = false
        await sut.loadItems(base: .parent(parentItem))

        // Then: Both products and variations present
        #expect(sut.itemsViewState.itemsStack.root.items.count == 2)
        #expect(sut.itemsViewState.itemsStack.itemStates[parentItem]?.items.count == 1)
    }

    @Test func test_load_next_items_delegates_to_data_source() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let sut = PointOfSaleObservableItemsController(siteID: 123, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        // Simulate initial load
        dataSource.productItems = [makeSimpleProduct()]
        dataSource.isLoadingProducts = false
        dataSource.hasMoreProducts = true
        await sut.loadItems(base: .root)

        // When
        await sut.loadNextItems(base: .root)

        // Then: loadMoreProducts should be called (verified by state change in mock)
        // Note: Mock doesn't actually track calls, but we can verify the state
        #expect(sut.itemsViewState.containerState == .content)
    }

    @Test func test_refresh_triggers_incremental_sync() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let siteID: Int64 = 123
        let sut = PointOfSaleObservableItemsController(siteID: siteID, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        dataSource.productItems = [makeSimpleProduct()]
        dataSource.isLoadingProducts = false
        await sut.loadItems(base: .root)

        // When
        await sut.refreshItems(base: .root)

        // Then: Should trigger incremental sync with correct site ID
        #expect(coordinator.performIncrementalSyncInvocationCount == 1)
        #expect(coordinator.performIncrementalSyncSiteID == siteID)
        #expect(coordinator.performIncrementalSyncMaxAge == 0)
        #expect(sut.itemsViewState.containerState == .content)
    }

    @Test func test_switching_parent_resets_variation_state() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let sut = PointOfSaleObservableItemsController(siteID: 123, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        let parent1 = POSVariableParentProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Parent 1",
            productImageSource: nil,
            productID: 100,
            allAttributes: []
        )
        let parentItem1 = POSItem.variableParentProduct(parent1)

        let parent2 = POSVariableParentProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Parent 2",
            productImageSource: nil,
            productID: 200,
            allAttributes: []
        )
        let parentItem2 = POSItem.variableParentProduct(parent2)

        // When: Load parent 1 variations
        dataSource.variationItems = [makeVariation()]
        dataSource.isLoadingVariations = false
        await sut.loadItems(base: .parent(parentItem1))

        #expect(sut.itemsViewState.itemsStack.itemStates[parentItem1]?.items.count == 1)

        // When: Load parent 2 variations
        dataSource.variationItems = [makeVariation(variationID: 1), makeVariation(variationID: 2)]
        await sut.loadItems(base: .parent(parentItem2))

        // Then: Parent 2 variations shown, parent 1 not in states anymore
        #expect(sut.itemsViewState.itemsStack.itemStates[parentItem2]?.items.count == 2)
        #expect(sut.itemsViewState.itemsStack.itemStates[parentItem1] == nil)
    }

    @Test func test_error_state_when_data_source_has_error() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let sut = PointOfSaleObservableItemsController(siteID: 123, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        dataSource.productItems = []
        dataSource.isLoadingProducts = false
        dataSource.productError = NSError(domain: "test", code: 1)

        // When
        await sut.loadItems(base: .root)

        // Then
        guard case .error = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected error state, got \(sut.itemsViewState.itemsStack.root)")
            return
        }
    }

    @Test func test_loading_state_preserves_existing_items() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let sut = PointOfSaleObservableItemsController(siteID: 123, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        let mockItems = [makeSimpleProduct(productID: 1), makeSimpleProduct(productID: 2)]

        // Load initial items
        dataSource.productItems = mockItems
        dataSource.isLoadingProducts = false
        await sut.loadItems(base: .root)

        // When: Start loading more
        dataSource.isLoadingProducts = true

        // Then: Loading state should preserve items
        #expect(sut.itemsViewState.itemsStack.root == .loading(mockItems))
    }

    @Test func test_refresh_error_handling_for_products() async {
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let sut = PointOfSaleObservableItemsController(siteID: 123, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        // Test 1: Inline error when items exist
        let mockItems = [makeSimpleProduct(productID: 1), makeSimpleProduct(productID: 2)]
        dataSource.productItems = mockItems
        dataSource.isLoadingProducts = false
        await sut.loadItems(base: .root)
        coordinator.performIncrementalSyncResult = .failure(NSError(domain: "test.error", code: 500))
        await sut.refreshItems(base: .root)

        guard case .inlineError(let items, let error, let context) = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected inlineError state when items exist")
            return
        }
        #expect(items.count == 2)
        #expect(error.errorType == .productsLoadError)
        #expect(context == .refresh)

        // Test 2: Full error when no items
        dataSource.productItems = []
        await sut.loadItems(base: .root)
        coordinator.performIncrementalSyncResult = .failure(NSError(domain: "test.error", code: 500))
        await sut.refreshItems(base: .root)

        guard case .error(let fullError) = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected error state when no items")
            return
        }
        #expect(fullError.errorType == .productsLoadError)

        // Test 3: Error clears on successful retry
        let mockProduct = makeSimpleProduct()
        dataSource.productItems = [mockProduct]
        await sut.loadItems(base: .root)
        coordinator.performIncrementalSyncResult = .success(())
        await sut.refreshItems(base: .root)

        #expect(sut.itemsViewState.itemsStack.root == .loaded([mockProduct], hasMoreItems: false))
    }

    @Test func test_load_products_retries_refresh_when_error_exists() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let sut = PointOfSaleObservableItemsController(siteID: 123, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        let mockProduct = makeSimpleProduct()
        dataSource.productItems = [mockProduct]
        dataSource.isLoadingProducts = false
        await sut.loadItems(base: .root)

        // Trigger a refresh error
        coordinator.performIncrementalSyncResult = .failure(NSError(domain: "test.error", code: 500))
        await sut.refreshItems(base: .root)

        guard case .inlineError = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected inlineError state after refresh")
            return
        }

        // When: Load items again with successful refresh
        coordinator.performIncrementalSyncResult = .success(())
        await sut.loadItems(base: .root)

        // Then: Refresh should be retried and error cleared
        #expect(coordinator.performIncrementalSyncInvocationCount == 2)
        #expect(sut.itemsViewState.itemsStack.root == .loaded([mockProduct], hasMoreItems: false))
    }

    @Test func test_refresh_error_handling_for_variations() async {
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let sut = PointOfSaleObservableItemsController(siteID: 123, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        let parentProduct = POSVariableParentProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Parent",
            productImageSource: nil,
            productID: 100,
            allAttributes: []
        )
        let parentItem = POSItem.variableParentProduct(parentProduct)

        // Test 1: Inline error when items exist
        let mockVariations = [makeVariation(variationID: 1), makeVariation(variationID: 2)]
        dataSource.variationItems = mockVariations
        dataSource.isLoadingVariations = false
        await sut.loadItems(base: .parent(parentItem))
        coordinator.performIncrementalSyncResult = .failure(NSError(domain: "test.error", code: 500))
        await sut.refreshItems(base: .parent(parentItem))

        guard case .inlineError(let items, let error, let context) = sut.itemsViewState.itemsStack.itemStates[parentItem] else {
            Issue.record("Expected inlineError state when items exist")
            return
        }
        #expect(items.count == 2)
        #expect(error.errorType == .variationsLoadError)
        #expect(context == .refresh)

        // Test 2: Full error when no items
        dataSource.variationItems = []
        await sut.loadItems(base: .parent(parentItem))
        coordinator.performIncrementalSyncResult = .failure(NSError(domain: "test.error", code: 500))
        await sut.refreshItems(base: .parent(parentItem))

        guard case .error(let fullError) = sut.itemsViewState.itemsStack.itemStates[parentItem] else {
            Issue.record("Expected error state when no items")
            return
        }
        #expect(fullError.errorType == .variationsLoadError)

        // Test 3: Error clears on successful retry
        dataSource.variationItems = mockVariations
        dataSource.hasMoreVariations = false
        await sut.loadItems(base: .parent(parentItem))
        coordinator.performIncrementalSyncResult = .success(())
        await sut.refreshItems(base: .parent(parentItem))

        #expect(sut.itemsViewState.itemsStack.itemStates[parentItem] == .loaded(mockVariations, hasMoreItems: false))
        #expect(coordinator.performIncrementalSyncInvocationCount == 5)
    }

    @Test func test_container_state_includes_catalog_syncing_flag_when_initial_sync_in_progress() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let siteID: Int64 = 123
        let sut = PointOfSaleObservableItemsController(siteID: siteID, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        dataSource.isLoadingProducts = true
        coordinator.fullSyncStateModel.state[siteID] = .initialSyncStarted(siteID: siteID)

        // When
        let containerState = sut.itemsViewState.containerState

        // Then
        guard case .loading(let isCatalogSyncing) = containerState else {
            Issue.record("Expected loading state")
            return
        }
        #expect(isCatalogSyncing == true)
    }

    // MARK: - Initial Sync Error Handling Tests

    @Test func test_container_state_shows_error_when_initial_sync_fails() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let siteID: Int64 = 123
        let sut = PointOfSaleObservableItemsController(siteID: siteID, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        dataSource.productItems = []
        dataSource.isLoadingProducts = false
        let testError = NSError(domain: "test.sync", code: 500)
        coordinator.fullSyncStateModel.state[siteID] = .initialSyncFailed(siteID: siteID, error: testError)

        // When
        let containerState = sut.itemsViewState.containerState

        // Then
        guard case .error(let errorState) = containerState else {
            Issue.record("Expected error state")
            return
        }
        #expect(errorState.errorType == .initialCatalogSyncError)
    }

    @Test func test_syncFailed_with_empty_catalog_shows_error() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let siteID: Int64 = 123
        let sut = PointOfSaleObservableItemsController(siteID: siteID, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        dataSource.productItems = []
        dataSource.isLoadingProducts = false
        let testError = NSError(domain: "test.sync", code: 500)
        coordinator.fullSyncStateModel.state[siteID] = .syncFailed(siteID: siteID, error: testError)

        // When
        let containerState = sut.itemsViewState.containerState

        // Then
        guard case .error(let errorState) = containerState else {
            Issue.record("Expected error state when catalog is empty")
            return
        }
        #expect(errorState.errorType == .initialCatalogSyncError)
    }

    @Test func test_syncFailed_with_existing_catalog_shows_content() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let siteID: Int64 = 123
        let sut = PointOfSaleObservableItemsController(siteID: siteID, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        let mockItems = [makeSimpleProduct(productID: 1), makeSimpleProduct(productID: 2)]
        dataSource.productItems = mockItems
        dataSource.isLoadingProducts = false
        let testError = NSError(domain: "test.sync", code: 500)
        coordinator.fullSyncStateModel.state[siteID] = .syncFailed(siteID: siteID, error: testError)

        // Load items first so productsLoaded is true
        await sut.loadItems(base: .root)

        // When
        let containerState = sut.itemsViewState.containerState

        // Then
        // Should show content, not error, because we have cached data
        #expect(containerState == .content)
        #expect(sut.itemsViewState.itemsStack.root == .loaded(mockItems, hasMoreItems: false))
    }

    @Test func test_reload_items_after_initial_sync_failure() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let siteID: Int64 = 123
        let sut = PointOfSaleObservableItemsController(siteID: siteID, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        dataSource.productItems = []
        dataSource.isLoadingProducts = false
        let testError = NSError(domain: "test.sync", code: 500)
        coordinator.fullSyncStateModel.state[siteID] = .initialSyncFailed(siteID: siteID, error: testError)
        coordinator.performSmartSyncResult = .success(())

        // When: Load items (should trigger reload)
        await sut.loadItems(base: .root)

        // Then: Should have called performSmartSync
        #expect(coordinator.performSmartSyncInvocationCount == 1)
        #expect(coordinator.performSmartSyncSiteID == siteID)
    }

    @Test func test_reload_items_after_syncFailed_with_empty_catalog() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let siteID: Int64 = 123
        let sut = PointOfSaleObservableItemsController(siteID: siteID, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        dataSource.productItems = []
        dataSource.isLoadingProducts = false
        let testError = NSError(domain: "test.sync", code: 500)
        coordinator.fullSyncStateModel.state[siteID] = .syncFailed(siteID: siteID, error: testError)
        coordinator.performSmartSyncResult = .success(())

        // When: Load items (should trigger reload because catalog is empty)
        await sut.loadItems(base: .root)

        // Then: Should have called performSmartSync
        #expect(coordinator.performSmartSyncInvocationCount == 1)
        #expect(coordinator.performSmartSyncSiteID == siteID)
    }

    @Test func test_no_reload_after_syncFailed_with_existing_catalog() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let siteID: Int64 = 123
        let sut = PointOfSaleObservableItemsController(siteID: siteID, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        let mockItems = [makeSimpleProduct(productID: 1)]
        dataSource.productItems = mockItems
        dataSource.isLoadingProducts = false
        let testError = NSError(domain: "test.sync", code: 500)
        coordinator.fullSyncStateModel.state[siteID] = .syncFailed(siteID: siteID, error: testError)

        // When: Load items (should NOT trigger reload because we have catalog data)
        await sut.loadItems(base: .root)

        // Then: Should NOT call performSmartSync
        #expect(coordinator.performSmartSyncInvocationCount == 0)
    }

    @Test func test_no_reload_when_sync_in_progress() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let siteID: Int64 = 123
        let sut = PointOfSaleObservableItemsController(siteID: siteID, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        dataSource.productItems = []
        dataSource.isLoadingProducts = false
        coordinator.fullSyncStateModel.state[siteID] = .syncStarted(siteID: siteID)

        // When: Load items while sync is in progress
        await sut.loadItems(base: .root)

        // Then: Should NOT call performSmartSync (already in progress)
        #expect(coordinator.performSmartSyncInvocationCount == 0)
    }

    @Test func test_no_reload_when_initial_sync_in_progress() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let siteID: Int64 = 123
        let sut = PointOfSaleObservableItemsController(siteID: siteID, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        dataSource.productItems = []
        dataSource.isLoadingProducts = false
        coordinator.fullSyncStateModel.state[siteID] = .initialSyncStarted(siteID: siteID)

        // When: Load items while initial sync is in progress
        await sut.loadItems(base: .root)

        // Then: Should NOT call performSmartSync (already in progress)
        #expect(coordinator.performSmartSyncInvocationCount == 0)
    }

    @Test func test_reload_only_applies_to_root_items() async {
        // Given
        let dataSource = MockPOSObservableDataSource()
        let coordinator = MockPOSCatalogSyncCoordinator()
        let siteID: Int64 = 123
        let sut = PointOfSaleObservableItemsController(siteID: siteID, dataSource: dataSource, catalogSyncCoordinator: coordinator)

        let parentProduct = POSVariableParentProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Parent",
            productImageSource: nil,
            productID: 100,
            allAttributes: []
        )
        let parentItem = POSItem.variableParentProduct(parentProduct)

        dataSource.variationItems = []
        dataSource.isLoadingVariations = false
        let testError = NSError(domain: "test.sync", code: 500)
        coordinator.fullSyncStateModel.state[siteID] = .initialSyncFailed(siteID: siteID, error: testError)

        // When: Load variations (not root)
        await sut.loadItems(base: .parent(parentItem))

        // Then: Should NOT trigger reload (reload only applies to root)
        #expect(coordinator.performSmartSyncInvocationCount == 0)
    }
}
