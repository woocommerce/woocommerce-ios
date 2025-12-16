import Testing
@testable import PointOfSale
import enum Yosemite.POSItemType
import enum Yosemite.SearchDebounceStrategy

struct POSProductSearchableTests {
    @Test func posProductSearchable_when_performSearch_is_called_then_delegates_to_controller_with_correct_parameters() async {
        // Given
        let mockController = MockPointOfSalePurchasableItemsSearchController()
        let mockSearchHistory = MockPOSSearchHistoryService()
        let sut = POSProductSearchable(
            itemListType: .products(),
            itemsController: mockController,
            searchHistoryProvider: mockSearchHistory
        )

        // When
        await sut.performSearch(term: "coffee")

        // Then
        #expect(mockController.searchItemsCalled)
        #expect(mockController.lastSearchTerm == "coffee")
    }

    @Test func posProductSearchable_when_clearSearchResults_is_called_then_delegates_to_controller() async {
        // Given
        let mockController = MockPointOfSalePurchasableItemsSearchController()
        let mockSearchHistory = MockPOSSearchHistoryService()
        let sut = POSProductSearchable(
            itemListType: .products(),
            itemsController: mockController,
            searchHistoryProvider: mockSearchHistory
        )

        // When
        await sut.clearSearchResults()

        // Then
        #expect(mockController.clearSearchItemsCalled)
    }

    @Test func posProductSearchable_when_searchHistory_is_accessed_then_returns_history_for_correct_item_and_item_type() {
        // Given
        let mockController = MockPointOfSalePurchasableItemsSearchController()
        let mockSearchHistory = MockPOSSearchHistoryService()
        mockSearchHistory.mockHistory = ["cappuccino", "latte"]
        let sut = POSProductSearchable(
            itemListType: .products(),
            itemsController: mockController,
            searchHistoryProvider: mockSearchHistory
        )

        // When
        let history = sut.searchHistory

        // Then
        #expect(history == ["cappuccino", "latte"])
        #expect(mockSearchHistory.lastRequestedItemType == .product)
    }

    @Test func posProductSearchable_when_searchFieldPlaceholder_is_accessed_then_returns_correct_placeholder() {
        // Given
        let mockController = MockPointOfSalePurchasableItemsSearchController()
        let mockSearchHistory = MockPOSSearchHistoryService()
        let sut = POSProductSearchable(
            itemListType: .products(),
            itemsController: mockController,
            searchHistoryProvider: mockSearchHistory
        )

        // When
        let placeholder = sut.searchFieldPlaceholder

        // Then
        #expect(placeholder == "Search products")
    }

    @Test func posProductSearchable_when_currentDebounceStrategy_is_accessed_then_returns_strategy_from_controller() {
        // Given
        let mockController = MockPointOfSalePurchasableItemsSearchController()
        mockController.currentDebounceStrategy = .immediate
        let mockSearchHistory = MockPOSSearchHistoryService()
        let sut = POSProductSearchable(
            itemListType: .products(),
            itemsController: mockController,
            searchHistoryProvider: mockSearchHistory
        )

        // When
        let strategy = sut.currentDebounceStrategy

        // Then
        #expect(strategy == .immediate)
    }

    @Test func posProductSearchable_when_searchDebounceStrategy_is_accessed_then_returns_strategy_from_controller() {
        // Given
        let mockController = MockPointOfSalePurchasableItemsSearchController()
        mockController.searchDebounceStrategy = .smart()
        let mockSearchHistory = MockPOSSearchHistoryService()
        let sut = POSProductSearchable(
            itemListType: .products(),
            itemsController: mockController,
            searchHistoryProvider: mockSearchHistory
        )

        // When
        let strategy = sut.searchDebounceStrategy

        // Then
        if case .smart = strategy {
            // Expected - test passes
        } else {
            Issue.record("Expected .smart debounce strategy")
        }
    }
}
