import Testing
import Foundation
@testable import WooCommerce
import protocol Yosemite.POSItem
@testable import struct Yosemite.POSProduct

struct PointOfSaleAggregateModelTests {
    private var itemProvider: MockPOSItemProvider
    private let sut: PointOfSaleAggregateModel

    init() {
        itemProvider = MockPOSItemProvider()
        sut = PointOfSaleAggregateModel(itemProvider: itemProvider)
    }

    @Test func itemListViewModel_when_loadInitialItems_then_first_page_requested() async throws {
        // Given
        try #require(sut.itemListState == .initialLoading)

        // When
        await sut.loadInitialItems()

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 1)
    }

    @Test func itemListViewModel_when_loadInitialItems_then_items_are_populated() async throws {
        // Given
        try #require(sut.itemListState == .initialLoading)
        let expectedItems = MockPOSItemProvider.makeInitialItems()

        // When
        await sut.loadInitialItems()

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
        await sut.loadInitialItems()
        await sut.loadInitialItems()
        await sut.loadInitialItems()

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
        await sut.reload()

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
        await sut.reload()
        await sut.reload()
        await sut.reload()

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
        await sut.loadInitialItems()

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
        await sut.loadNextItems()

        // Then
        #expect(sut.itemListState == .empty)
    }

    @Test func loadItems_when_initial_items_has_items_then_state_is_loaded_with_initial_items() async throws {
        // Given
        let initialItems = MockPOSItemProvider.makeInitialItems()
        itemProvider.items = initialItems

        try #require(sut.itemListState == .initialLoading)

        // When
        await sut.loadNextItems()

        // Then
        #expect(sut.itemListState == .loaded(initialItems))
    }

    @Test func loadItems_when_simulateFetchNextPage_then_returns_expected_items() async throws {
        // Given
        let initialItems = MockPOSItemProvider.makeInitialItems()
        itemProvider.items = initialItems
        itemProvider.shouldSimulateTwoPages = true

        // When
        await sut.loadNextItems()

        // Then
        guard case .loaded(let items) = sut.itemListState else {
            Issue.record("Expected loaded ItemList state, but got \(sut.itemListState)")
            return
        }
        #expect(items.count == 4)
    }

    @Test func itemListViewModel_when_loadNextItems_then_second_page_requested() async throws {
        // Given
        try #require(sut.itemListState == .initialLoading)

        // When
        await sut.loadNextItems()

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 2)
    }

    @Test func itemListViewModel_when_loadInitialItems_has_no_items_then_state_is_loaded_empty() async throws {
        // Given
        let itemProvider = MockPOSItemProvider()
        itemProvider.shouldReturnZeroItems = true
        let sut = PointOfSaleAggregateModel(itemProvider: itemProvider)

        try #require(sut.itemListState == .initialLoading)

        // When
        await sut.loadInitialItems()

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
        await sut.loadInitialItems()

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
        await sut.loadNextItems()

        // Then
        #expect(sut.itemListState == .error(expectedError))
    }

    @Test func itemListViewModel_when_itemProvider_throws_error_then_the_same_page_is_requested_next() async throws {
        // Given
        itemProvider.shouldThrowError = true
        await sut.loadNextItems()
        try #require(itemProvider.spyLastRequestedPageNumber == 2)
        itemProvider.spyLastRequestedPageNumber = 0

        // When
        await sut.loadNextItems()

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 2)
    }

    @Test func itemListViewModel_when_reload_then_state_is_loaded_with_expected_items() async throws {
        // Given
        try #require(sut.itemListState == .initialLoading)
        let expectedItems = MockPOSItemProvider.makeInitialItems()

        // When
        await sut.reload()

        // Then
        #expect(sut.itemListState == .loaded(expectedItems))
    }

    @Test func itemListViewModel_when_reload_then_first_page_requested() async throws {
        // Given
        await sut.loadNextItems()
        try #require(itemProvider.spyLastRequestedPageNumber == 2)

        // When
        await sut.reload()

        // Then
        #expect(itemProvider.spyLastRequestedPageNumber == 1)
    }

    @Test func itemListViewModel_when_reload_throws_error_then_state_is_error() async throws {
        // Given
        itemProvider.shouldThrowError = true
        let expectedError = PointOfSaleErrorState(title: "Error loading products",
                                               subtitle: "Give it another go?",
                                               buttonText: "Retry")

        try #require(sut.itemListState == .initialLoading)

        // When
        await sut.reload()

        // Then
        #expect(sut.itemListState == .error(expectedError))
    }

    struct CartTests {
        let sut: PointOfSaleAggregateModel
        private var analytics: WooAnalytics!
        private var analyticsProvider: MockAnalyticsProvider!

        init() {
            analyticsProvider = MockAnalyticsProvider()
            analytics = WooAnalytics(analyticsProvider: analyticsProvider)
            sut = PointOfSaleAggregateModel(itemProvider: MockPOSItemProvider(),
                                            analytics: analytics)
        }

        @Test func addItem_results_in_a_non_empty_cart() async throws {
            // Given
            try #require(sut.cart.isEmpty)
            let item = Self.makeItem()

            // When
            sut.addToCart(item)

            // Then
            #expect(sut.cart.isNotEmpty)
        }

        @Test func addItem_puts_new_items_first_in_the_cart() async throws {
            // Given
            let items = [Self.makeItem(), Self.makeItem(), Self.makeItem()]

            // When
            items.forEach(sut.addToCart(_:))

            // Then
            #expect(sut.cart.map(\.item.itemID) == items.reversed().map(\.itemID))
        }

        @Test func removeItem_after_adding_two_items_removes_item_correctly() async throws {
            // Given
            let item = Self.makeItem(name: "Item 1")
            let anotherItem = Self.makeItem(name: "Item 2")

            sut.addToCart(item)
            sut.addToCart(anotherItem)
            try #require(sut.cart.count == 2)

            // When
            let firstItem = try #require(sut.cart.first)
            sut.remove(cartItem: firstItem)

            // Then
            #expect(sut.cart.count == 1)
            #expect(sut.cart.first?.item.name == item.name)
        }

        @Test func removeAllItemsFromCart_removes_everything() async throws {
            // Given
            let item = Self.makeItem(name: "Item 1")
            let anotherItem = Self.makeItem(name: "Item 2")

            sut.addToCart(item)
            sut.addToCart(anotherItem)
            try #require(sut.cart.count == 2)

            // When
            sut.removeAllItemsFromCart()

            // Then
            #expect(sut.cart.isEmpty)
        }

        @Test(.disabled(
            """
            This test doesn't currently work; analytics extensions are not thread-safe,
            and using the MainActor means the assert happens too early. I don't think
            we want the addToCart to be async, but that would be one way to fix it.
            """))
        func addToCart_tracks_analytics_event() async throws {
            // Given
            let item = Self.makeItem()

            // When
            sut.addToCart(item)

            // Then
            let event = try #require(analyticsProvider.receivedEvents.first)
            #expect(event == "pos_item_added_to_cart")
        }

        static func makeItem(name: String = "") -> POSItem {
            return POSProduct(itemID: UUID(),
                              productID: 0,
                              name: name,
                              price: "",
                              formattedPrice: "",
                              itemCategories: [],
                              productImageSource: nil,
                              productType: .simple)
        }
    }
}
