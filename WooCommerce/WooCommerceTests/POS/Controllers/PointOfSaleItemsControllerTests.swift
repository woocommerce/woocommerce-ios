import Testing
import Foundation
import Combine
@testable import WooCommerce
import struct Yosemite.POSVariableParentProduct
import enum Yosemite.POSItem

final class PointOfSaleItemsControllerTests {
    private let itemProvider: MockPointOfSaleItemService
    private let sut: PointOfSaleItemsController
    @Published var itemsViewState: ItemsViewState = ItemsViewState(containerState: .loading,
                                                                   itemsStack: ItemsStackState(root: .loading([]),
                                                                                               itemStates: [:]))

    init() {
        itemProvider = MockPointOfSaleItemService()
        sut = PointOfSaleItemsController(itemProvider: itemProvider)
        sut.itemsViewStatePublisher.assign(to: &$itemsViewState)
    }

    @Test func loadItems_requests_first_page_after_loading_two_pages() async throws {
        // Given
        try #require(itemsViewState.containerState == .loading)
        itemProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root)

        await sut.loadNextItems(base: .root)
        try #require(itemProvider.spyLastRequestedPageNumber == 2)

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 1)
    }

    @Test func loadItems_results_in_loaded_state() async throws {
        // Given
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [expectedItems]
        try #require(itemsViewState.containerState == .loading)

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(itemsViewState == ItemsViewState(containerState: .content,
                                                 itemsStack: ItemsStackState(root: .loaded(expectedItems, hasMoreItems: false),
                                                                             itemStates: [:])))
    }

    @Test func loadItems_with_more_pages_sets_hasMoreItems() async throws {
        // Given
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        try #require(itemsViewState.containerState == .loading)
        itemProvider.shouldSimulateTwoPages = true

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(itemsViewState == ItemsViewState(containerState: .content,
                                                 itemsStack: ItemsStackState(root: .loaded(expectedItems, hasMoreItems: true),
                                                                             itemStates: [:])))
    }

    @Test func loadItems_when_called_multiple_times_then_items_are_not_duplicated() async throws {
        // Given
        try #require(itemsViewState.containerState == .loading)
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [expectedItems]

        // When
        await sut.loadItems(base: .root)
        await sut.loadItems(base: .root)
        await sut.loadItems(base: .root)

        // Then
        guard case .loaded(let items, _) = itemsViewState.itemsStack.root else {
            Issue.record("Expected loaded ItemList state, but got \(itemsViewState)")
            return
        }
        #expect(items.count == expectedItems.count)
    }

    @Test func container_state_starts_as_loading() {
        // Given/When/Then
        #expect(itemsViewState.containerState == .loading)
    }

    @Test func loadNextItems_when_initial_items_empty_then_container_state_is_empty() async throws {
        // Given
        itemProvider.shouldReturnZeroItems = true

        try #require(itemsViewState.containerState == .loading)

        // When
        await sut.loadNextItems(base: .root)

        // Then
        #expect(itemsViewState.containerState == .empty)
    }

    @Test func loadItems_when_initial_items_has_items_but_no_more_pages_then_state_is_loaded_with_initial_items() async throws {
        // Given
        let initialItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [initialItems]

        try #require(itemsViewState.containerState == .loading)

        // When
        await sut.loadNextItems(base: .root)

        // Then
        #expect(itemsViewState == ItemsViewState(containerState: .content,
                                                 itemsStack: ItemsStackState(root: .loaded(initialItems, hasMoreItems: false),
                                                                             itemStates: [:])))
    }

    @Test func loadNextItems_when_simulateFetchNextPage_then_state_is_loaded_with_expected_items() async throws {
        // Given
        let initialItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root)

        // When
        await sut.loadNextItems(base: .root)

        // Then
        guard case .loaded(let items, _) = itemsViewState.itemsStack.root else {
            Issue.record("Expected loaded ItemList state, but got \(itemsViewState)")
            return
        }
        #expect(items.count == 4)
    }

    @Test func loadNextItems_requests_second_page() async throws {
        // Given
        try #require(itemsViewState.containerState == .loading)
        itemProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root)

        // When
        await sut.loadNextItems(base: .root)

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 2)
    }

    @Test func loadNextItems_when_simulateFetchNextPage_then_state_is_loaded_with_hasMoreItems() async throws {
        // Given
        let initialItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.shouldSimulateTwoPages = true
        itemProvider.shouldSimulateMorePages = true
        await sut.loadItems(base: .root)

        // When
        await sut.loadNextItems(base: .root)

        // Then
        guard case .loaded(let items, let hasMoreItems) = itemsViewState.itemsStack.root else {
            Issue.record("Expected loaded ItemList state, but got \(itemsViewState)")
            return
        }
        #expect(hasMoreItems)
        #expect(items.count == 4)
    }

    @Test func loadNextItems_child_when_simulateFetchNextPage_then_state_is_loaded_with_hasMoreItems() async throws {
        // Given
        let parentItem = POSItem.variableParentProduct(POSVariableParentProduct(id: UUID(),
                                                                                name: "Fake Parent",
                                                                                productImageSource: nil,
                                                                                productID: 12345))
        let baseItem = ItemListBaseItem.parent(parentItem)
        itemProvider.shouldSimulateTwoPagesOfVariations = true
        itemProvider.shouldSimulateMorePagesOfVariations = true

        await sut.loadItems(base: .root)
        await sut.loadItems(base: baseItem)

        // When
        await sut.loadNextItems(base: baseItem)

        // Then
        guard case .loaded(let items, let hasMoreItems) = itemsViewState.itemsStack.itemStates[parentItem] else {
            Issue.record("Expected loaded ItemList state, but got \(itemsViewState)")
            return
        }
        #expect(hasMoreItems)
        #expect(items.count == 4)
    }

    @Test func loadNextItems_child_when_service_throws_then_state_is_inlineError() async throws {
        // Given
        let parentItem = POSItem.variableParentProduct(POSVariableParentProduct(id: UUID(),
                                                                                name: "Fake Parent",
                                                                                productImageSource: nil,
                                                                                productID: 12345))
        let baseItem = ItemListBaseItem.parent(parentItem)
        itemProvider.shouldSimulateTwoPagesOfVariations = true

        await sut.loadItems(base: .root)
        await sut.loadItems(base: baseItem)

        itemProvider.shouldThrowError = true

        // When
        await sut.loadNextItems(base: baseItem)

        // Then
        guard case .inlineError(let items, let errorState) = itemsViewState.itemsStack.itemStates[parentItem] else {
            Issue.record("Expected inlineError ItemList state, but got \(itemsViewState)")
            return
        }
        #expect(items.count == 2)
        #expect(errorState == PointOfSaleErrorState.errorOnLoadingVariationsNextPage())
    }

    @Test func loadItems_when_no_items_then_state_is_loaded_empty() async throws {
        // Given
        itemProvider.shouldReturnZeroItems = true

        try #require(itemsViewState.containerState == .loading)

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(itemsViewState.containerState == .empty)
    }

    @Test func loadItems_when_itemProvider_throws_error_then_state_is_error() async throws {
        // Given
        itemProvider.shouldThrowError = true
        let expectedError = PointOfSaleErrorState(title: "Error loading products",
                                                  subtitle: "Give it another go?",
                                                  buttonText: "Retry")
        try #require(itemsViewState.containerState == .loading)

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(itemsViewState.containerState == .error(expectedError))
    }

    @Test func loadNextItems_when_itemProvider_throws_error_then_state_is_inlineError() async throws {
        // Given
        try #require(itemsViewState.containerState == .loading)

        itemProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root)

        itemProvider.shouldThrowError = true

        // When
        await sut.loadNextItems(base: .root)

        // Then
        #expect(itemsViewState.containerState == .content)

        guard case .inlineError(let items, let errorState) = itemsViewState.itemsStack.root else {
            Issue.record("Expected inlineError ItemList state, but got \(itemsViewState)")
            return
        }
        #expect(items.count == 2)
        #expect(errorState == PointOfSaleErrorState.errorOnLoadingProductsNextPage())
    }

    @Test func loadNextItems_after_itemProvider_throws_error_then_the_same_page_is_requested_next() async throws {
        // Given
        itemProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root)

        itemProvider.shouldThrowError = true
        await sut.loadNextItems(base: .root)
        try #require(itemProvider.spyLastRequestedPageNumber == 2)
        itemProvider.spyLastRequestedPageNumber = 0

        // When
        await sut.loadNextItems(base: .root)

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 2)
    }

    @Test func loadItems_results_in_state_loaded_with_expected_items() async throws {
        // Given
        try #require(itemsViewState.containerState == .loading)
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [expectedItems]

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(itemsViewState == ItemsViewState(containerState: .content,
                                                 itemsStack: ItemsStackState(root: .loaded(expectedItems, hasMoreItems: false),
                                                                             itemStates: [:])))
    }

    @Test func loadNextItems_when_next_page_is_empty_then_state_is_loaded() async throws {
        // Given
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [expectedItems]
        await sut.loadItems(base: .root)
        try #require(itemProvider.spyLastRequestedPageNumber == 1)

        // When
        itemProvider.shouldReturnZeroItems = true
        await sut.loadNextItems(base: .root)

        // Then
        #expect(itemsViewState == ItemsViewState(containerState: .content,
                                                 itemsStack: ItemsStackState(root: .loaded(expectedItems,
                                                                                           hasMoreItems: false),
                                                                             itemStates: [:])))
    }

    @Test func loadNextItems_when_next_page_is_empty_then_the_same_page_is_requested_next() async throws {
        // Given
        await sut.loadItems(base: .root)
        try #require(itemProvider.spyLastRequestedPageNumber == 1)

        // When
        itemProvider.shouldReturnZeroItems = true
        await sut.loadNextItems(base: .root)

        // Then
        try #require(itemProvider.spyLastRequestedPageNumber == 1)
    }

    @Test func loadItems_sets_root_items_to_loading_state_while_preserving_existing_items() async throws {
        // Given
        let initialItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [initialItems]
        await sut.loadItems(base: .root)
        try #require(itemsViewState.itemsStack.root.items == initialItems)

        var states: [ItemListState] = []
        let cancellable = sut.itemsViewStatePublisher
            .sink { state in
                states.append(state.itemsStack.root)
            }

        // When
        await sut.loadItems(base: .root)

        // Then
        let loadingStates = states.filter { $0.isLoading }
        #expect(loadingStates.count == 1)
        if case .loading(let items) = loadingStates.first {
            #expect(items == initialItems)
        }
        cancellable.cancel()
    }

    @Test func loadItems_sets_container_state_to_loading_and_root_state_to_loading_state_when_no_existing_items() async throws {
        // Given
        itemProvider.shouldReturnZeroItems = true
        await sut.loadItems(base: .root)
        try #require(itemsViewState.itemsStack.root.items == [])

        var states: [ItemsViewState] = []
        let cancellable = sut.itemsViewStatePublisher
            .sink { state in
                states.append(state)
            }

        // When
        await sut.loadItems(base: .root)

        // Then
        let loadingStates = states.filter { $0.containerState == .loading }
        #expect(loadingStates.count == 1)
        #expect(loadingStates.first?.itemsStack.root == .loading([]))
        cancellable.cancel()
    }

    @Test func loadItems_preserves_itemStates() async throws {
        // Given
        let parentItem = POSItem.variableParentProduct(POSVariableParentProduct(id: UUID(),
                                                                              name: "Parent product",
                                                                              productImageSource: nil,
                                                                              productID: 125))
        itemProvider.itemPages = [[parentItem]]
        await sut.loadItems(base: .root)
        await sut.loadItems(base: .parent(parentItem))
        let itemStates = itemsViewState.itemsStack.itemStates
        try #require(itemStates != [:])

        // When
        await sut.loadItems(base: .root)

        // Then
        try #require(itemsViewState.itemsStack.itemStates == itemStates)
    }

    @Test func loadItems_sets_child_items_to_loading_state_while_preserving_existing_items() async throws {
        // Given
        let parentItem = POSItem.variableParentProduct(POSVariableParentProduct(id: UUID(),
                                                                              name: "Parent product",
                                                                              productImageSource: nil,
                                                                              productID: 125))
        let baseItem = ItemListBaseItem.parent(parentItem)
        itemProvider.itemPages = [[parentItem]]

        // Loads initial items.
        await sut.loadItems(base: .root)
        await sut.loadItems(base: baseItem)

        let initialChildItems = itemsViewState.itemsStack.itemStates[parentItem]?.items ?? []
        try #require(!initialChildItems.isEmpty)

        var states: [ItemListState] = []
        let cancellable = sut.itemsViewStatePublisher.sink { state in
            if let childState = state.itemsStack.itemStates[parentItem] {
                states.append(childState)
            }
        }

        // When
        await sut.loadItems(base: baseItem)

        // Then
        let loadingStates = states.filter { $0.isLoading }
        #expect(loadingStates.count == 1)
        if case .loading(let items) = loadingStates.first {
            #expect(items == initialChildItems)
        }
        cancellable.cancel()
    }
}
