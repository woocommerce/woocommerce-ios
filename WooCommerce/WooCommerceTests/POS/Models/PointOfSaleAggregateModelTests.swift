import Testing
import Foundation
@testable import WooCommerce

struct PointOfSaleAggregateModelTests {
    private var itemProvider: MockPOSItemProvider
    private let sut: PointOfSaleAggregateModel

    init() {
        itemProvider = MockPOSItemProvider()
        sut = PointOfSaleAggregateModel(itemProvider: itemProvider)
    }

    @Test func itemListViewModel_when_loadInitialItems_then_items_are_populated() async throws {
        // Given
        try #require(sut.itemListState == .initialLoading)
        let expectedItems = MockPOSItemProvider.makeInitialItems()

        // When
        try? await sut.loadInitialItems()

        // Then
        guard case .loaded(let items) = sut.itemListState else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemListState)")
            return
        }
        #expect(items.count == expectedItems.count)
    }

    @Test func itemListViewModel_when_loadInitialItems_is_called_multiple_times_then_items_are_not_aggregated() async throws {
        // Given
        try #require(sut.itemListState == .initialLoading)
        let expectedItems = MockPOSItemProvider.makeInitialItems()

        // When
        try? await sut.loadInitialItems()
        try? await sut.loadInitialItems()
        try? await sut.loadInitialItems()

        // Then
        guard case .loaded(let items) = sut.itemListState else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemListState)")
            return
        }
        #expect(items.count == expectedItems.count)
    }

    @Test func itemListViewModel_when_reload_is_called_then_items_are_populated() async throws {
        // Given
        try #require(sut.itemListState == .initialLoading)
        let expectedItems = MockPOSItemProvider.makeInitialItems()

        // When
        try? await sut.reload()

        // Then
        guard case .loaded(let items) = sut.itemListState else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemListState)")
            return
        }
        #expect(items.count == expectedItems.count)
    }

    @Test func itemListViewModel_when_reload_is_called_multiple_times_then_items_are_not_aggregated() async throws {
        // Given
        try #require(sut.itemListState == .initialLoading)
        let expectedItems = MockPOSItemProvider.makeInitialItems()

        // When
        try? await sut.reload()
        try? await sut.reload()
        try? await sut.reload()

        // Then
        guard case .loaded(let items) = sut.itemListState else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemListState)")
            return
        }
        #expect(items.count == expectedItems.count)
    }

    @Test func itemListViewModel_when_initilized_then_state_is_initialLoading() {
        // Given/When/Then
        #expect(sut.itemListState == .initialLoading)
    }

    @Test func itemListViewModel_when_loadInitialItems_then_state_is_loaded() async throws {
        // Given
        let expectedItems = MockPOSItemProvider.makeInitialItems()
        try #require(sut.itemListState == .initialLoading)

        // When
        try? await sut.loadInitialItems()

        // Then
        #expect(sut.itemListState == .loaded(expectedItems))
    }

    @Test func loadItems_when_initial_items_empty_then_state_is_empty() async throws {
        // Given
        let itemProvider = MockPOSItemProvider()
        itemProvider.shouldReturnZeroItems = true
        let sut = PointOfSaleAggregateModel(itemProvider: itemProvider)

        try #require(sut.itemListState == .initialLoading)

        // When
        try? await sut.loadItems(pageNumber: 2)

        // Then
        #expect(sut.itemListState == .empty)
    }

    @Test func loadItems_when_initial_items_has_items_then_state_is_loaded_with_initial_items() async throws {
        // Given
        let initialItems = MockPOSItemProvider.makeInitialItems()
        itemProvider.items = initialItems

        try #require(sut.itemListState == .initialLoading)

        // When
        try? await sut.loadItems(pageNumber: 2)

        // Then
        #expect(sut.itemListState == .loaded(initialItems))
    }

    @Test func loadItems_when_simulateFetchNextPage_then_returns_expected_items() async throws {
        // Given
        let initialItems = MockPOSItemProvider.makeInitialItems()
        itemProvider.items = initialItems
        itemProvider.shouldSimulateTwoPages = true

        // When
        try? await sut.loadItems(pageNumber: 2)

        // Then
        guard case .loaded(let items) = sut.itemListState else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemListState)")
            return
        }
        #expect(items.count == 4)
    }

    @Test func itemListViewModel_when_loadInitialItems_has_no_items_then_state_is_loaded_empty() async throws {
        // Given
        let itemProvider = MockPOSItemProvider()
        itemProvider.shouldReturnZeroItems = true
        let sut = PointOfSaleAggregateModel(itemProvider: itemProvider)

        try #require(sut.itemListState == .initialLoading)

        // When
        try? await sut.loadInitialItems()

        // Then
        #expect(sut.itemListState == .empty)
    }

    @Test func itemListViewModel_when_loadInitialItems_throws_error_then_state_is_error() async throws {
        // Given
        itemProvider.shouldThrowError = true
        let expectedError = PointOfSaleErrorState(title: "Error loading products",
                                               subtitle: "Give it another go?",
                                               buttonText: "Retry")
        try #require(sut.itemListState == .initialLoading)

        // When
        try? await sut.loadInitialItems()

        // Then
        #expect(sut.itemListState == .error(expectedError))
    }

    @Test func itemListViewModel_when_itemProvider_throws_error_then_state_is_error() async throws {
        // Given
        itemProvider.shouldThrowError = true
        let expectedError = PointOfSaleErrorState(title: "Error loading products",
                                               subtitle: "Give it another go?",
                                               buttonText: "Retry")
        try #require(sut.itemListState == .initialLoading)

        // When
        try? await sut.loadItems(pageNumber: 2)

        // Then
        #expect(sut.itemListState == .error(expectedError))
    }

    @Test func itemListViewModel_when_itemProvider_throws_error_then_it_is_thrown() async throws {
        // Given
        itemProvider.shouldThrowError = true

        // Then
        await #expect(throws: MockPOSItemProvider.MockError.requestFailed) {
            // When
            try await sut.loadItems(pageNumber: 2)
        }
    }


    @Test func itemListViewModel_when_reload_then_state_is_loaded_with_expected_items() async throws {
        // Given
        try #require(sut.itemListState == .initialLoading)
        let expectedItems = MockPOSItemProvider.makeInitialItems()

        // When
        try? await sut.reload()

        // Then
        #expect(sut.itemListState == .loaded(expectedItems))
    }

    @Test func itemListViewModel_when_reload_throws_error_then_state_is_error() async throws {
        // Given
        itemProvider.shouldThrowError = true
        let expectedError = PointOfSaleErrorState(title: "Error loading products",
                                               subtitle: "Give it another go?",
                                               buttonText: "Retry")

        try #require(sut.itemListState == .initialLoading)

        // When
        try? await sut.reload()

        // Then
        #expect(sut.itemListState == .error(expectedError))
    }
}
