import Testing
import Combine
@testable import WooCommerce

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

    @Test func loadInitialItems_requests_first_page() async throws {
        // Given
        try #require(itemsViewState.containerState == .loading)

        // When
        await sut.loadInitialItems()

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 1)
    }

    @Test func loadInitialItems_results_in_loaded_state() async throws {
        // Given
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        try #require(itemsViewState.containerState == .loading)

        // When
        await sut.loadInitialItems()

        // Then
        #expect(itemsViewState == ItemsViewState(containerState: .content,
                                                 itemsStack: ItemsStackState(root: .loaded(expectedItems, hasMoreItems: false),
                                                                             itemStates: [:])))
    }

    @Test func loadInitialItems_when_called_multiple_times_then_items_are_not_duplicated() async throws {
        // Given
        try #require(itemsViewState.containerState == .loading)
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()

        // When
        await sut.loadInitialItems()
        await sut.loadInitialItems()
        await sut.loadInitialItems()

        // Then
        guard case .loaded(let items, _) = itemsViewState.itemsStack.root else {
            Issue.record("Expected loaded ItemList state, but got \(itemsViewState)")
            return
        }
        #expect(items.count == expectedItems.count)
    }

    @Test func reload_results_in_loaded_state() async throws {
        // Given
        try #require(itemsViewState.containerState == .loading)
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()

        // When
        await sut.reload()

        // Then
        guard case .loaded(let items, _) = itemsViewState.itemsStack.root else {
            Issue.record("Expected loaded ItemList state, but got \(itemsViewState)")
            return
        }
        #expect(items.count == expectedItems.count)
    }

    @Test func reload_when_called_multiple_times_then_items_are_not_duplicated() async throws {
        // Given
        try #require(itemsViewState.containerState == .loading)
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()

        // When
        await sut.reload()
        await sut.reload()
        await sut.reload()

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

    @Test func loadItems_when_initial_items_empty_then_container_state_is_empty() async throws {
        // Given
        itemProvider.shouldReturnZeroItems = true

        try #require(itemsViewState.containerState == .loading)

        // When
        await sut.loadNextItems()

        // Then
        #expect(itemsViewState.containerState == .empty)
    }

    @Test func loadItems_when_initial_items_has_items_then_state_is_loaded_with_initial_items() async throws {
        // Given
        let initialItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.items = initialItems

        try #require(itemsViewState.containerState == .loading)

        // When
        await sut.loadNextItems()

        // Then
        #expect(itemsViewState == ItemsViewState(containerState: .content,
                                                 itemsStack: ItemsStackState(root: .loaded(initialItems, hasMoreItems: false),
                                                                             itemStates: [:])))
    }

    @Test func loadItems_when_simulateFetchNextPage_then_state_is_loaded_with_expected_items() async throws {
        // Given
        let initialItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.items = initialItems
        itemProvider.shouldSimulateTwoPages = true
        await sut.loadInitialItems()

        // When
        await sut.loadNextItems()

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
        await sut.loadInitialItems()

        // When
        await sut.loadNextItems()

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 2)
    }

    @Test func loadInitialItems_when_no_items_then_state_is_loaded_empty() async throws {
        // Given
        itemProvider.shouldReturnZeroItems = true

        try #require(itemsViewState.containerState == .loading)

        // When
        await sut.loadInitialItems()

        // Then
        #expect(itemsViewState.containerState == .empty)
    }

    @Test func loadInitialItems_when_itemProvider_throws_error_then_state_is_error() async throws {
        // Given
        itemProvider.shouldThrowError = true
        let expectedError = PointOfSaleErrorState(title: "Error loading products",
                                                  subtitle: "Give it another go?",
                                                  buttonText: "Retry")
        try #require(itemsViewState.containerState == .loading)

        // When
        await sut.loadInitialItems()

        // Then
        #expect(itemsViewState.containerState == .error(expectedError))
    }

    @Test func loadNextItems_when_itemProvider_throws_error_then_state_is_error() async throws {
        // Given
        try #require(itemsViewState.containerState == .loading)

        itemProvider.shouldSimulateTwoPages = true
        await sut.loadInitialItems()

        itemProvider.shouldThrowError = true
        let expectedError = PointOfSaleErrorState(title: "Error loading products",
                                                  subtitle: "Give it another go?",
                                                  buttonText: "Retry")

        // When
        await sut.loadNextItems()

        // Then
        #expect(itemsViewState.containerState == .error(expectedError))
    }

    @Test func loadNextItems_after_itemProvider_throws_error_then_the_same_page_is_requested_next() async throws {
        // Given
        itemProvider.shouldSimulateTwoPages = true
        await sut.loadInitialItems()

        itemProvider.shouldThrowError = true
        await sut.loadNextItems()
        try #require(itemProvider.spyLastRequestedPageNumber == 2)
        itemProvider.spyLastRequestedPageNumber = 0

        // When
        await sut.loadNextItems()

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 2)
    }

    @Test func reload_results_in_state_loaded_with_expected_items() async throws {
        // Given
        try #require(itemsViewState.containerState == .loading)
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()

        // When
        await sut.reload()

        // Then
        #expect(itemsViewState == ItemsViewState(containerState: .content,
                                                 itemsStack: ItemsStackState(root: .loaded(expectedItems, hasMoreItems: false),
                                                                             itemStates: [:])))
    }

    @Test func reload_requests_first_page() async throws {
        // Given
        itemProvider.shouldSimulateTwoPages = true
        await sut.loadInitialItems()

        await sut.loadNextItems()
        try #require(itemProvider.spyLastRequestedPageNumber == 2)

        // When
        await sut.reload()

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 1)
    }

    @Test func loadNextItems_when_next_page_is_empty_then_state_is_loaded() async throws {
        // Given
        await sut.loadInitialItems()
        try #require(itemProvider.spyLastRequestedPageNumber == 1)

        // When
        itemProvider.shouldReturnZeroItems = true
        await sut.loadNextItems()

        // Then
        #expect(itemsViewState == ItemsViewState(containerState: .content,
                                                 itemsStack: ItemsStackState(root: .loaded(MockPointOfSaleItemService.makeInitialItems(),
                                                                                           hasMoreItems: false),
                                                                             itemStates: [:])))
    }

    @Test func loadNextItems_when_next_page_is_empty_then_the_same_page_is_requested_next() async throws {
        // Given
        await sut.loadInitialItems()
        try #require(itemProvider.spyLastRequestedPageNumber == 1)

        // When
        itemProvider.shouldReturnZeroItems = true
        await sut.loadNextItems()

        // Then
        try #require(itemProvider.spyLastRequestedPageNumber == 1)
    }

    @Test func reload_when_itemProvider_throws_error_then_state_is_error() async throws {
        // Given
        itemProvider.shouldThrowError = true
        let expectedError = PointOfSaleErrorState(title: "Error loading products",
                                                  subtitle: "Give it another go?",
                                                  buttonText: "Retry")

        try #require(itemsViewState.containerState == .loading)

        // When
        await sut.reload()

        // Then
        #expect(itemsViewState.containerState == .error(expectedError))
    }
}
