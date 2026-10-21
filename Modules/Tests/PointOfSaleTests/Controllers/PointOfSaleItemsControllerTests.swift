import Testing
import Foundation
@testable import PointOfSale
import struct Yosemite.POSVariableParentProduct
import enum Yosemite.POSItem
import struct Yosemite.POSItemIdentifier
import enum Yosemite.PointOfSaleItemServiceError
import class Yosemite.PointOfSaleItemFetchStrategyFactory
import WooFoundation
@testable import struct Yosemite.PointOfSaleSearchPurchasableItemFetchStrategy

@Suite(.timeLimit(.minutes(5)))
@MainActor
final class PointOfSaleItemsControllerTests {
    @Test func loadItems_requests_first_page_after_loading_two_pages() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        try #require(sut.itemsViewState.containerState == .loading())
        itemProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root)

        await sut.loadNextItems(base: .root)
        try #require(itemProvider.spyLastRequestedPageNumber == 2)

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 1)
        #expect(sut.itemsViewState.itemsStack.root == .loaded(MockPointOfSaleItemService.makeInitialItems(), hasMoreItems: true))
    }

    @Test func loadItems_results_in_loaded_state() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [expectedItems]
        try #require(sut.itemsViewState.containerState == .loading())

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState == ItemsViewState(containerState: .content,
                                                     itemsStack: ItemsStackState(root: .loaded(expectedItems, hasMoreItems: false),
                                                                                 itemStates: [:])))
    }

    @Test func loadItems_with_more_pages_sets_hasMoreItems() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        try #require(sut.itemsViewState.containerState == .loading())
        itemProvider.shouldSimulateTwoPages = true

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState == ItemsViewState(containerState: .content,
                                                     itemsStack: ItemsStackState(root: .loaded(expectedItems, hasMoreItems: true),
                                                                                 itemStates: [:])))
    }

    @Test func loadItems_when_called_multiple_times_then_items_are_not_duplicated() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        try #require(sut.itemsViewState.containerState == .loading())
        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [expectedItems]

        // When
        await sut.loadItems(base: .root)
        await sut.loadItems(base: .root)
        await sut.loadItems(base: .root)

        // Then
        guard case .loaded(let items, _) = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemsViewState)")
            return
        }
        #expect(items == expectedItems)
    }

    @Test func container_state_starts_as_loading() {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        // When/Then
        #expect(sut.itemsViewState.containerState == .loading())
    }

    @Test func loadNextItems_when_initial_items_empty_then_container_state_is_content_and_root_state_is_empty() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        itemProvider.shouldReturnZeroItems = true

        try #require(sut.itemsViewState.containerState == .loading())

        // When
        await sut.loadNextItems(base: .root)

        // Then
        #expect(sut.itemsViewState.containerState == .content)
        #expect(sut.itemsViewState.itemsStack.root == .empty)
    }

    @Test func loadItems_when_initial_items_has_items_but_no_more_pages_then_state_is_loaded_with_initial_items() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        let initialItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [initialItems]

        try #require(sut.itemsViewState.containerState == .loading())

        // When
        await sut.loadNextItems(base: .root)

        // Then
        #expect(sut.itemsViewState == ItemsViewState(containerState: .content,
                                                     itemsStack: ItemsStackState(root: .loaded(initialItems, hasMoreItems: false),
                                                                                 itemStates: [:])))
    }

    @Test func loadNextItems_when_simulateFetchNextPage_then_state_is_loaded_with_expected_items() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        itemProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root)

        // When
        await sut.loadNextItems(base: .root)

        // Then
        guard case .loaded(let items, _) = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemsViewState)")
            return
        }
        #expect(items == MockPointOfSaleItemService.makeInitialItems() + MockPointOfSaleItemService.makeSecondPageItems())
    }

    @Test func loadNextItems_when_simulateFetchNextPage_then_state_is_loaded_with_hasMoreItems() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        itemProvider.shouldSimulateTwoPages = true
        itemProvider.shouldSimulateMorePages = true
        await sut.loadItems(base: .root)

        // When
        await sut.loadNextItems(base: .root)

        // Then
        guard case .loaded(let items, let hasMoreItems) = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemsViewState)")
            return
        }
        #expect(hasMoreItems)
        #expect(items == MockPointOfSaleItemService.makeInitialItems() + MockPointOfSaleItemService.makeSecondPageItems())
    }

    @Test func loadNextItems_child_when_simulateFetchNextPage_then_state_is_loaded_with_hasMoreItems() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        let parentItem = POSItem.variableParentProduct(POSVariableParentProduct(id: POSItemIdentifier(underlyingType: .product, itemID: 1),
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
        guard case .loaded(let items, let hasMoreItems) = sut.itemsViewState.itemsStack.itemStates[parentItem] else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemsViewState)")
            return
        }
        #expect(hasMoreItems)
        #expect(items == MockPointOfSaleItemService.makeInitialVariationItems() + MockPointOfSaleItemService.makeSecondPageVariationItems())
    }

    @Test func loadNextItems_child_when_service_throws_then_state_is_inlineError() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        let parentItem = POSItem.variableParentProduct(POSVariableParentProduct(id: POSItemIdentifier(underlyingType: .product, itemID: 1),
                                                                                name: "Fake Parent",
                                                                                productImageSource: nil,
                                                                                productID: 12345))
        let baseItem = ItemListBaseItem.parent(parentItem)
        itemProvider.shouldSimulateTwoPagesOfVariations = true

        await sut.loadItems(base: .root)
        await sut.loadItems(base: baseItem)

        itemProvider.errorToThrow = MockError.requestFailed

        // When
        await sut.loadNextItems(base: baseItem)

        // Then
        guard case .inlineError(let items, let errorState, let context) = sut.itemsViewState.itemsStack.itemStates[parentItem] else {
            Issue.record("Expected inlineError ItemList state, but got \(sut.itemsViewState)")
            return
        }
        #expect(items == MockPointOfSaleItemService.makeInitialVariationItems())
        #expect(errorState == PointOfSaleErrorState.errorOnLoadingVariationsNextPage())
        #expect(context == .pagination)
    }

    @Test func loadItems_when_no_items_then_container_state_is_content_and_root_state_is_empty() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        itemProvider.shouldReturnZeroItems = true

        try #require(sut.itemsViewState.containerState == .loading())

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState.containerState == .content)
        #expect(sut.itemsViewState.itemsStack.root == .empty)
    }

    @Test func loadItems_when_itemProvider_throws_error_then_state_is_error() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        itemProvider.errorToThrow = MockError.requestFailed
        try #require(sut.itemsViewState.containerState == .loading())

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState.containerState == .content)
        #expect(sut.itemsViewState.itemsStack.root == .error(.errorOnLoadingProducts()))
    }

    @Test func loadNextItems_when_itemProvider_throws_error_then_state_is_inlineError() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        try #require(sut.itemsViewState.containerState == .loading())

        itemProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root)

        itemProvider.errorToThrow = MockError.requestFailed

        // When
        await sut.loadNextItems(base: .root)

        // Then
        #expect(sut.itemsViewState.containerState == .content)

        guard case .inlineError(let items, let errorState, let context) = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected inlineError ItemList state, but got \(sut.itemsViewState)")
            return
        }
        #expect(items == MockPointOfSaleItemService.makeInitialItems())
        #expect(errorState == PointOfSaleErrorState.errorOnLoadingProductsNextPage())
        #expect(context == .pagination)
    }

    @Test func loadNextItems_after_itemProvider_throws_error_then_the_same_page_is_requested_next() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        itemProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root)

        itemProvider.errorToThrow = MockError.requestFailed
        await sut.loadNextItems(base: .root)
        try #require(itemProvider.spyLastRequestedPageNumber == 2)
        itemProvider.spyLastRequestedPageNumber = 0
        itemProvider.errorToThrow = nil

        // When
        await sut.loadNextItems(base: .root)

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 2)
        #expect(sut.itemsViewState.itemsStack.root == .loaded(
            MockPointOfSaleItemService.makeInitialItems() + MockPointOfSaleItemService.makeSecondPageItems(), hasMoreItems: false))
    }

    @Test func loadNextItems_when_next_page_is_empty_then_state_is_loaded() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [expectedItems, []]
        await sut.loadItems(base: .root)
        try #require(sut.itemsViewState.itemsStack.root == .loaded(expectedItems, hasMoreItems: true))

        // When
        itemProvider.shouldReturnZeroItems = true
        await sut.loadNextItems(base: .root)

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 2)
        #expect(sut.itemsViewState == ItemsViewState(containerState: .content,
                                                     itemsStack: ItemsStackState(root: .loaded(expectedItems,
                                                                                               hasMoreItems: false),
                                                                                 itemStates: [:])))
    }

    @Test func loadNextItems_when_no_more_pages_then_preserves_items_without_fetching() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        let expectedItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [expectedItems]
        await sut.loadItems(base: .root)
        try #require(itemProvider.spyLastRequestedPageNumber == 1)

        // When
        itemProvider.shouldReturnZeroItems = true
        await sut.loadNextItems(base: .root)

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 1)
        #expect(sut.itemsViewState.itemsStack.root == .loaded(expectedItems, hasMoreItems: false))
    }

    @Test func loadItems_sets_root_items_to_loading_state_while_preserving_existing_items() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        let initialItems = MockPointOfSaleItemService.makeInitialItems()
        itemProvider.itemPages = [initialItems]
        await sut.loadItems(base: .root)
        try #require(sut.itemsViewState.itemsStack.root.items == initialItems)

        var observedLoading = false
        itemProvider.onProvideItems = { [weak sut] in
            observedLoading = true
            #expect(sut?.itemsViewState.itemsStack.root == .loading(initialItems))
        }

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(observedLoading)
        #expect(sut.itemsViewState.itemsStack.root == .loaded(initialItems, hasMoreItems: false))
    }

    @Test func loadItems_preserves_itemStates() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        let parentItem = POSItem.variableParentProduct(POSVariableParentProduct(id: POSItemIdentifier(underlyingType: .product, itemID: 1),
                                                                                name: "Parent product",
                                                                                productImageSource: nil,
                                                                                productID: 125))
        itemProvider.itemPages = [[parentItem]]
        await sut.loadItems(base: .root)
        await sut.loadItems(base: .parent(parentItem))
        let itemStates = sut.itemsViewState.itemsStack.itemStates
        try #require(itemStates != [:])

        // When
        await sut.loadItems(base: .root)

        // Then
        try #require(sut.itemsViewState.itemsStack.itemStates == itemStates)
    }

    @Test func loadItems_sets_child_items_to_loading_state_while_preserving_existing_items() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
        )

        let parentItem = POSItem.variableParentProduct(POSVariableParentProduct(id: POSItemIdentifier(underlyingType: .product, itemID: 1),
                                                                                name: "Parent product",
                                                                                productImageSource: nil,
                                                                                productID: 125))
        let baseItem = ItemListBaseItem.parent(parentItem)
        itemProvider.itemPages = [[parentItem]]

        // Loads initial items.
        await sut.loadItems(base: .root)
        await sut.loadItems(base: baseItem)

        let initialChildItems = sut.itemsViewState.itemsStack.itemStates[parentItem]?.items ?? []
        try #require(!initialChildItems.isEmpty)

        var observedLoading = false
        itemProvider.onProvideVariationItems = { [weak sut] in
            observedLoading = true
            #expect(sut?.itemsViewState.itemsStack.itemStates[parentItem] == .loading(initialChildItems))
        }

        // When
        await sut.loadItems(base: baseItem)

        // Then
        #expect(observedLoading)
        #expect(sut.itemsViewState.itemsStack.itemStates[parentItem] == .loaded(initialChildItems, hasMoreItems: false))
    }

    @Test func search_sets_a_fetch_strategy_with_search_term_on_the_service() async throws {
        // Given
        let itemProvider = MockPointOfSaleItemService()
        let sut = PointOfSaleItemsController(
            itemProvider: itemProvider,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory(siteID: 1, credentials: nil, currencySettings: CurrencySettings()),
            analyticsProvider: MockPOSAnalytics()
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
