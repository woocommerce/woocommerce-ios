import Testing
import Foundation
@testable import WooCommerce
import struct Yosemite.POSVariableParentProduct
import enum Yosemite.POSItem
import enum Yosemite.PointOfSaleItemServiceError
import class Yosemite.PointOfSaleItemFetchStrategyFactory
@testable import struct Yosemite.PointOfSaleSearchPurchasableItemFetchStrategy
import Observation

final class PointOfSaleItemsControllerTests {
    @available(iOS 17.0, *)
    @Test func loadItems_requests_first_page_after_loading_two_pages() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        try #require(sut.itemsViewState.containerState == .loading)
        itemProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root(.products))

        await sut.loadNextItems(base: .root(.products))
        try #require(itemProvider.spyLastRequestedPageNumber == 2)

        // When
        await sut.loadItems(base: .root(.products))

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 1)
    }

    @available(iOS 17.0, *)
    @Test func loadItems_results_in_loaded_state() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [expectedItems]
        try #require(sut.itemsViewState.containerState == .loading)

        // When
        await sut.loadItems(base: .root(.products))

        // Then
        #expect(sut.itemsViewState == ItemsViewState(containerState: .content,
                                                     itemsStack: ItemsStackState(root: .loaded(expectedItems, hasMoreItems: false),
                                                                                 itemStates: [:])))
    }

    @available(iOS 17.0, *)
    @Test func loadItems_with_more_pages_sets_hasMoreItems() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        try #require(sut.itemsViewState.containerState == .loading)
        itemProvider.shouldSimulateTwoPages = true

        // When
        await sut.loadItems(base: .root(.products))

        // Then
        #expect(sut.itemsViewState == ItemsViewState(containerState: .content,
                                                     itemsStack: ItemsStackState(root: .loaded(expectedItems, hasMoreItems: true),
                                                                                 itemStates: [:])))
    }

    @available(iOS 17.0, *)
    @Test func loadItems_when_called_multiple_times_then_items_are_not_duplicated() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        try #require(sut.itemsViewState.containerState == .loading)
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [expectedItems]

        // When
        await sut.loadItems(base: .root(.products))
        await sut.loadItems(base: .root(.products))
        await sut.loadItems(base: .root(.products))

        // Then
        guard case .loaded(let items, _) = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemsViewState)")
            return
        }
        #expect(items.count == expectedItems.count)
    }

    @available(iOS 17.0, *)
    @Test func container_state_starts_as_loading() {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        // When/Then
        #expect(sut.itemsViewState.containerState == .loading)
    }

    @available(iOS 17.0, *)
    @Test func loadNextItems_when_initial_items_empty_then_container_state_is_empty() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        itemProvider.shouldReturnZeroItems = true

        try #require(sut.itemsViewState.containerState == .loading)

        // When
        await sut.loadNextItems(base: .root(.products))

        // Then
        #expect(sut.itemsViewState.containerState == .empty)
    }

    @available(iOS 17.0, *)
    @Test func loadItems_when_initial_items_has_items_but_no_more_pages_then_state_is_loaded_with_initial_items() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        let initialItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [initialItems]

        try #require(sut.itemsViewState.containerState == .loading)

        // When
        await sut.loadNextItems(base: .root(.products))

        // Then
        #expect(sut.itemsViewState == ItemsViewState(containerState: .content,
                                                     itemsStack: ItemsStackState(root: .loaded(initialItems, hasMoreItems: false),
                                                                                 itemStates: [:])))
    }

    @available(iOS 17.0, *)
    @Test func loadNextItems_when_simulateFetchNextPage_then_state_is_loaded_with_expected_items() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        itemProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root(.products))

        // When
        await sut.loadNextItems(base: .root(.products))

        // Then
        guard case .loaded(let items, _) = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemsViewState)")
            return
        }
        #expect(items.count == 4)
    }

    @available(iOS 17.0, *)
    @Test func loadNextItems_requests_second_page() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        try #require(sut.itemsViewState.containerState == .loading)
        itemProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root(.products))

        // When
        await sut.loadNextItems(base: .root(.products))

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 2)
    }

    @available(iOS 17.0, *)
    @Test func loadNextItems_when_simulateFetchNextPage_then_state_is_loaded_with_hasMoreItems() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        itemProvider.shouldSimulateTwoPages = true
        itemProvider.shouldSimulateMorePages = true
        await sut.loadItems(base: .root(.products))

        // When
        await sut.loadNextItems(base: .root(.products))

        // Then
        guard case .loaded(let items, let hasMoreItems) = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemsViewState)")
            return
        }
        #expect(hasMoreItems)
        #expect(items.count == 4)
    }

    @available(iOS 17.0, *)
    @Test func loadNextItems_child_when_simulateFetchNextPage_then_state_is_loaded_with_hasMoreItems() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        let parentItem = POSItem.variableParentProduct(POSVariableParentProduct(id: UUID(),
                                                                                name: "Fake Parent",
                                                                                productImageSource: nil,
                                                                                productID: 12345))
        let baseItem = ItemListBaseItem.parent(parentItem, .products)
        itemProvider.shouldSimulateTwoPagesOfVariations = true
        itemProvider.shouldSimulateMorePagesOfVariations = true

        await sut.loadItems(base: .root(.products))
        await sut.loadItems(base: baseItem)

        // When
        await sut.loadNextItems(base: baseItem)

        // Then
        guard case .loaded(let items, let hasMoreItems) = sut.itemsViewState.itemsStack.itemStates[parentItem] else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemsViewState)")
            return
        }
        #expect(hasMoreItems)
        #expect(items.count == 4)
    }

    @available(iOS 17.0, *)
    @Test func loadNextItems_child_when_service_throws_then_state_is_inlineError() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        let parentItem = POSItem.variableParentProduct(POSVariableParentProduct(id: UUID(),
                                                                                name: "Fake Parent",
                                                                                productImageSource: nil,
                                                                                productID: 12345))
        let baseItem = ItemListBaseItem.parent(parentItem, .products)
        itemProvider.shouldSimulateTwoPagesOfVariations = true

        await sut.loadItems(base: .root(.products))
        await sut.loadItems(base: baseItem)

        itemProvider.errorToThrow = MockError.requestFailed

        // When
        await sut.loadNextItems(base: baseItem)

        // Then
        guard case .inlineError(let items, let errorState) = sut.itemsViewState.itemsStack.itemStates[parentItem] else {
            Issue.record("Expected inlineError ItemList state, but got \(sut.itemsViewState)")
            return
        }
        #expect(items.count == 2)
        #expect(errorState == PointOfSaleErrorState.errorOnLoadingVariationsNextPage())
    }

    @available(iOS 17.0, *)
    @Test func loadItems_when_no_items_then_state_is_loaded_empty() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        itemProvider.shouldReturnZeroItems = true

        try #require(sut.itemsViewState.containerState == .loading)

        // When
        await sut.loadItems(base: .root(.products))

        // Then
        #expect(sut.itemsViewState.containerState == .empty)
    }

    @available(iOS 17.0, *)
    @Test func loadItems_when_itemProvider_throws_error_then_state_is_error() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        itemProvider.errorToThrow = MockError.requestFailed
        let expectedError = PointOfSaleErrorState(title: "Error loading products",
                                                  subtitle: "Give it another go?",
                                                  buttonText: "Retry")
        try #require(sut.itemsViewState.containerState == .loading)

        // When
        await sut.loadItems(base: .root(.products))

        // Then
        #expect(sut.itemsViewState.containerState == .error(expectedError))
    }

    @available(iOS 17.0, *)
    @Test func loadNextItems_when_itemProvider_throws_error_then_state_is_inlineError() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        try #require(sut.itemsViewState.containerState == .loading)

        itemProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root(.products))

        itemProvider.errorToThrow = MockError.requestFailed

        // When
        await sut.loadNextItems(base: .root(.products))

        // Then
        #expect(sut.itemsViewState.containerState == .content)

        guard case .inlineError(let items, let errorState) = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected inlineError ItemList state, but got \(sut.itemsViewState)")
            return
        }
        #expect(items.count == 2)
        #expect(errorState == PointOfSaleErrorState.errorOnLoadingProductsNextPage())
    }

    @available(iOS 17.0, *)
    @Test func loadItems_when_request_is_cancelled_then_state_is_loaded() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        itemProvider.errorToThrow = PointOfSaleItemServiceError.requestCancelled
        try #require(sut.itemsViewState.containerState == .loading)

        // When
        await sut.loadItems(base: .root(.products))

        // Then
        guard case .loaded(let items, let hasMoreItems) = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemsViewState.itemsStack.root)")
            return
        }
        #expect(items.count == 0)
        #expect(hasMoreItems)
    }

    @available(iOS 17.0, *)
    @Test func loadNextItems_when_request_is_cancelled_then_state_is_loaded() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        itemProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root(.products))

        guard case .loaded = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemsViewState.itemsStack.root)")
            return
        }

        itemProvider.errorToThrow = PointOfSaleItemServiceError.requestCancelled

        // When
        await sut.loadNextItems(base: .root(.products))

        // Then
        #expect(sut.itemsViewState.containerState == .content)

        guard case .loaded(let items, let hasMoreItems) = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemsViewState.itemsStack.root)")
            return
        }
        #expect(items.count == 2)
        #expect(hasMoreItems)
    }

    @available(iOS 17.0, *)
    @Test func loadNextItems_after_itemProvider_throws_error_then_the_same_page_is_requested_next() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        itemProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root(.products))

        itemProvider.errorToThrow = MockError.requestFailed
        await sut.loadNextItems(base: .root(.products))
        try #require(itemProvider.spyLastRequestedPageNumber == 2)
        itemProvider.spyLastRequestedPageNumber = 0

        // When
        await sut.loadNextItems(base: .root(.products))

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 2)
    }

    @available(iOS 17.0, *)
    @Test func loadItems_results_in_state_loaded_with_expected_items() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        try #require(sut.itemsViewState.containerState == .loading)
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [expectedItems]

        // When
        await sut.loadItems(base: .root(.products))

        // Then
        #expect(sut.itemsViewState == ItemsViewState(containerState: .content,
                                                     itemsStack: ItemsStackState(root: .loaded(expectedItems, hasMoreItems: false),
                                                                                 itemStates: [:])))
    }

    @available(iOS 17.0, *)
    @Test func loadNextItems_when_next_page_is_empty_then_state_is_loaded() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [expectedItems]
        await sut.loadItems(base: .root(.products))
        try #require(itemProvider.spyLastRequestedPageNumber == 1)

        // When
        itemProvider.shouldReturnZeroItems = true
        await sut.loadNextItems(base: .root(.products))

        // Then
        #expect(sut.itemsViewState == ItemsViewState(containerState: .content,
                                                     itemsStack: ItemsStackState(root: .loaded(expectedItems,
                                                                                               hasMoreItems: false),
                                                                                 itemStates: [:])))
    }

    @available(iOS 17.0, *)
    @Test func loadNextItems_when_next_page_is_empty_then_the_same_page_is_requested_next() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        await sut.loadItems(base: .root(.products))
        try #require(itemProvider.spyLastRequestedPageNumber == 1)

        // When
        itemProvider.shouldReturnZeroItems = true
        await sut.loadNextItems(base: .root(.products))

        // Then
        try #require(itemProvider.spyLastRequestedPageNumber == 1)
    }

    @available(iOS 17.0, *)
    @Test func loadItems_sets_root_items_to_loading_state_while_preserving_existing_items() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        let initialItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [initialItems]
        await sut.loadItems(base: .root(.products))
        try #require(sut.itemsViewState.itemsStack.root.items == initialItems)

        await confirmation() { confirmation in
            withObservationTracking {
                _ = sut.itemsViewState.itemsStack.root
            } onChange: {
                // Then
                Task { @MainActor in
                    // Dispatched in a task because `onChange` is called with `willSet` semantics 🙄
                    #expect(sut.itemsViewState.itemsStack.root == .loading(initialItems))
                    confirmation()
                }
            }

            // When
            await sut.loadItems(base: .root(.products))
        }
    }

    @available(iOS 17.0, *)
    @Test func loadItems_sets_container_state_to_loading_and_root_state_to_loading_state_when_no_existing_items() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        itemProvider.shouldReturnZeroItems = true

        await confirmation() { confirmation in
            withObservationTracking {
                _ = sut.itemsViewState.containerState
            } onChange: {
                // Then
                Task { @MainActor in
                    #expect(sut.itemsViewState.containerState == .loading)
                    #expect(sut.itemsViewState.itemsStack.root == .loading([]))
                    confirmation()
                }
            }

            // When
            await sut.loadItems(base: .root(.products))
        }
    }

    @available(iOS 17.0, *)
    @Test func loadItems_preserves_itemStates() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        let parentItem = POSItem.variableParentProduct(POSVariableParentProduct(id: UUID(),
                                                                              name: "Parent product",
                                                                              productImageSource: nil,
                                                                              productID: 125))
        itemProvider.itemPages = [[parentItem]]
        await sut.loadItems(base: .root(.products))
        await sut.loadItems(base: .parent(parentItem, .products))
        let itemStates = sut.itemsViewState.itemsStack.itemStates
        try #require(itemStates != [:])

        // When
        await sut.loadItems(base: .root(.products))

        // Then
        try #require(sut.itemsViewState.itemsStack.itemStates == itemStates)
    }

    @available(iOS 17.0, *)
    @Test func loadItems_sets_child_items_to_loading_state_while_preserving_existing_items() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        let parentItem = POSItem.variableParentProduct(POSVariableParentProduct(id: UUID(),
                                                                              name: "Parent product",
                                                                              productImageSource: nil,
                                                                              productID: 125))
        let baseItem = ItemListBaseItem.parent(parentItem, .products)
        itemProvider.itemPages = [[parentItem]]

        // Loads initial items.
        await sut.loadItems(base: .root(.products))
        await sut.loadItems(base: baseItem)

        let initialChildItems = sut.itemsViewState.itemsStack.itemStates[parentItem]?.items ?? []
        try #require(!initialChildItems.isEmpty)

        await confirmation() { confirmation in
            withObservationTracking {
                _ = sut.itemsViewState.itemsStack.itemStates[parentItem]
            } onChange: {
                // Then
                Task { @MainActor in
                    #expect(sut.itemsViewState.itemsStack.itemStates[parentItem] == .loading(initialChildItems))
                    confirmation()
                }
            }

            // When
            await sut.loadItems(base: baseItem)
        }
    }

    @available(iOS 17.0, *)
    @Test func loadChildItems_when_request_is_cancelled_then_state_is_loaded() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        let parentItem = POSItem.variableParentProduct(POSVariableParentProduct(id: UUID(),
                                                                              name: "Parent product",
                                                                              productImageSource: nil,
                                                                              productID: 125))
        let baseItem = ItemListBaseItem.parent(parentItem, .products)

        itemProvider.errorToThrow = PointOfSaleItemServiceError.requestCancelled
        try #require(sut.itemsViewState.containerState == .loading)

        // When
        await sut.loadItems(base: baseItem)

        // Then
        guard case .loaded(let items, let hasMoreItems) = sut.itemsViewState.itemsStack.itemStates[parentItem] else {
            Issue.record("Expected loaded ItemList state, but got \(String(describing: sut.itemsViewState.itemsStack.itemStates[parentItem]))")
            return
        }
        #expect(items.count == 0)
        #expect(hasMoreItems)
    }

    @available(iOS 17.0, *)
    @Test func loadNextChildItems_when_request_is_cancelled_then_state_is_loaded() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        let parentItem = POSItem.variableParentProduct(POSVariableParentProduct(id: UUID(),
                                                                              name: "Parent product",
                                                                              productImageSource: nil,
                                                                              productID: 125))
        let baseItem = ItemListBaseItem.parent(parentItem, .products)

        itemProvider.shouldSimulateTwoPagesOfVariations = true
        await sut.loadItems(base: baseItem)

        itemProvider.errorToThrow = PointOfSaleItemServiceError.requestCancelled

        // When
        await sut.loadNextItems(base: baseItem)

        // Then
        #expect(sut.itemsViewState.containerState == .content)

        guard case .loaded(let items, let hasMoreItems) = sut.itemsViewState.itemsStack.itemStates[parentItem] else {
            Issue.record("Expected loaded ItemList state, but got \(String(describing: sut.itemsViewState.itemsStack.itemStates[parentItem]))")
            return
        }
        #expect(items.count == 2)
        #expect(hasMoreItems)
    }

    @available(iOS 17.0, *)
    @Test func search_sets_a_fetch_strategy_with_search_term_on_the_service() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil)
        )

        // When
        await sut.searchItems(searchTerm: "green mug", baseItem: .root)

        // Then
        let fetchStrategy = try #require(itemProvider.spyItemsFetchStrategy as? PointOfSaleSearchPurchasableItemFetchStrategy)
        #expect(fetchStrategy.searchTerm == "green mug")
    }

    enum MockError: Error {
        case requestFailed
    }
}
