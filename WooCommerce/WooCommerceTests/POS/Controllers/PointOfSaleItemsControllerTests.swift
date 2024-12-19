import Testing
import Combine
@testable import WooCommerce

final class PointOfSaleItemsControllerTests {
    private let itemProvider: MockPointOfSaleItemService
    private let sut: PointOfSaleItemsController
    @Published var itemListState: ItemListState = .initialLoading

    init() {
        itemProvider = MockPointOfSaleItemService()
        sut = PointOfSaleItemsController(itemProvider: itemProvider)
        sut.itemListStatePublisher.assign(to: &$itemListState)
    }

    @Test func loadInitialItems_requests_first_page() async throws {
        // Given
        try #require(itemListState == .initialLoading)

        // When
        await sut.loadInitialItems()

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 1)
    }

    @Test func loadInitialItems_results_in_loaded_state() async throws {
        // Given
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        try #require(itemListState == .initialLoading)

        // When
        await sut.loadInitialItems()

        // Then
        #expect(itemListState == .loaded(expectedItems))
    }

    @Test func loadInitialItems_when_called_multiple_times_then_items_are_not_duplicated() async throws {
        // Given
        try #require(itemListState == .initialLoading)
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()

        // When
        await sut.loadInitialItems()
        await sut.loadInitialItems()
        await sut.loadInitialItems()

        // Then
        guard case .loaded(let items) = itemListState else {
            Issue.record("Expected loaded ItemList state, but got \(itemListState)")
            return
        }
        #expect(items.count == expectedItems.count)
    }

    @Test func reload_results_in_loaded_state() async throws {
        // Given
        try #require(itemListState == .initialLoading)
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()

        // When
        await sut.reload()

        // Then
        guard case .loaded(let items) = itemListState else {
            Issue.record("Expected loaded ItemList state, but got \(itemListState)")
            return
        }
        #expect(items.count == expectedItems.count)
    }

    @Test func reload_when_called_multiple_times_then_items_are_not_duplicated() async throws {
        // Given
        try #require(itemListState == .initialLoading)
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()

        // When
        await sut.reload()
        await sut.reload()
        await sut.reload()

        // Then
        guard case .loaded(let items) = itemListState else {
            Issue.record("Expected loaded ItemList state, but got \(itemListState)")
            return
        }
        #expect(items.count == expectedItems.count)
    }

    @Test func state_starts_as_initialLoading() {
        // Given/When/Then
        #expect(itemListState == .initialLoading)
    }

    @Test func loadItems_when_initial_items_empty_then_state_is_empty() async throws {
        // Given
        itemProvider.shouldReturnZeroItems = true

        try #require(itemListState == .initialLoading)

        // When
        await sut.loadNextItems()

        // Then
        #expect(itemListState == .empty)
    }

    @Test func loadItems_when_initial_items_has_items_then_state_is_loaded_with_initial_items() async throws {
        // Given
        let initialItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.items = initialItems

        try #require(itemListState == .initialLoading)

        // When
        await sut.loadNextItems()

        // Then
        #expect(itemListState == .loaded(initialItems))
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
        guard case .loaded(let items) = itemListState else {
            Issue.record("Expected loaded ItemList state, but got \(itemListState)")
            return
        }
        #expect(items.count == 4)
    }

    @Test func loadNextItems_requests_second_page() async throws {
        // Given
        try #require(itemListState == .initialLoading)
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

        try #require(itemListState == .initialLoading)

        // When
        await sut.loadInitialItems()

        // Then
        #expect(itemListState == .empty)
    }

    @Test func loadInitialItems_when_itemProvider_throws_error_then_state_is_error() async throws {
        // Given
        itemProvider.shouldThrowError = true
        let expectedError = PointOfSaleErrorState(title: "Error loading products",
                                                  subtitle: "Give it another go?",
                                                  buttonText: "Retry")
        try #require(itemListState == .initialLoading)

        // When
        await sut.loadInitialItems()

        // Then
        #expect(itemListState == .error(expectedError))
    }

    @Test func loadNextItems_when_itemProvider_throws_error_then_state_is_error() async throws {
        // Given
        try #require(itemListState == .initialLoading)

        itemProvider.shouldSimulateTwoPages = true
        await sut.loadInitialItems()

        itemProvider.shouldThrowError = true
        let expectedError = PointOfSaleErrorState(title: "Error loading products",
                                                  subtitle: "Give it another go?",
                                                  buttonText: "Retry")

        // When
        await sut.loadNextItems()

        // Then
        #expect(itemListState == .error(expectedError))
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
        try #require(itemListState == .initialLoading)
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()

        // When
        await sut.reload()

        // Then
        #expect(itemListState == .loaded(expectedItems))
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
        #expect(itemListState == .loaded(MockPointOfSaleItemService.makeInitialItems()))
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

        try #require(itemListState == .initialLoading)

        // When
        await sut.reload()

        // Then
        #expect(itemListState == .error(expectedError))
    }
}
