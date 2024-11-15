import Testing
import Foundation
@testable import WooCommerce
import protocol Yosemite.POSItem
@testable import struct Yosemite.POSProduct
import struct Yosemite.Order
import Combine

struct PointOfSaleAggregateModelTests {
    struct OrderStageTests {
        private let sut: PointOfSaleAggregateModel

        init() {
            self.sut = PointOfSaleAggregateModel(itemProvider: MockPOSItemProvider(),
                                                 cardPresentPaymentService: MockCardPresentPaymentService(),
                                                 orderService: MockPOSOrderService())
        }

        @Test func inits_with_building_order_stage() async throws {
            #expect(sut.orderStage == .building)
        }

        @Test func startNewCart_removes_all_items_from_cart_and_moves_back_to_building() async throws {
            // Given
            sut.addToCart(makeItem())
            await sut.submitCart()
            try #require(sut.orderStage == .finalizing)
            try #require(sut.cart.isNotEmpty)

            // When
            sut.startNewCart()

            // Then
            #expect(sut.orderStage == .building)
            #expect(sut.cart.isEmpty)
        }

        @Test func submitCart_moves_to_finalizing_order_stage() async throws {
            // Given
            sut.addToCart(makeItem())

            // When
            await sut.submitCart()

            // Then
            #expect(sut.orderStage == .finalizing)
        }

        @Test func addMoreToCart_moves_to_building_order_stage() async throws {
            // Given
            sut.addToCart(makeItem())
            await sut.submitCart()
            try #require(sut.orderStage == .finalizing)

            // When
            sut.addMoreToCart()

            // Then
            #expect(sut.orderStage == .building)
        }

    }

    struct ItemListTests {
        private let itemProvider: MockPOSItemProvider
        private let sut: PointOfSaleAggregateModel

        init() {
            itemProvider = MockPOSItemProvider()
            sut = PointOfSaleAggregateModel(itemProvider: itemProvider,
                                            cardPresentPaymentService: MockCardPresentPaymentService(),
                                            orderService: MockPOSOrderService())
        }

        @Test func loadInitialItems_requests_first_page() async throws {
            // Given
            try #require(sut.itemListState == .initialLoading)

            // When
            await sut.loadInitialItems()

            // Then
            #expect(itemProvider.spyLastRequestedPageNumber == 1)
        }

        @Test func loadInitialItems_results_in_loaded_state() async throws {
            // Given
            let expectedItems = MockPOSItemProvider.makeInitialItems()
            try #require(sut.itemListState == .initialLoading)

            // When
            await sut.loadInitialItems()

            // Then
            #expect(sut.itemListState == .loaded(expectedItems))
        }

        @Test func loadInitialItems_when_called_multiple_times_then_items_are_not_duplicated() async throws {
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

        @Test func reload_results_in_loaded_state() async throws {
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

        @Test func reload_when_called_multiple_times_then_items_are_not_duplicated() async throws {
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

        @Test func state_starts_as_initialLoading() {
            // Given/When/Then
            #expect(sut.itemListState == .initialLoading)
        }

        @Test func loadItems_when_initial_items_empty_then_state_is_empty() async throws {
            // Given
            let itemProvider = MockPOSItemProvider()
            itemProvider.shouldReturnZeroItems = true
            let sut = PointOfSaleAggregateModel(itemProvider: itemProvider,
                                                cardPresentPaymentService: MockCardPresentPaymentService(),
                                                orderService: MockPOSOrderService())

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

        @Test func loadItems_when_simulateFetchNextPage_then_state_is_loaded_with_expected_items() async throws {
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

        @Test func loadNextItems_requests_second_page() async throws {
            // Given
            try #require(sut.itemListState == .initialLoading)

            // When
            await sut.loadNextItems()

            // Then
            #expect(itemProvider.spyLastRequestedPageNumber == 2)
        }

        @Test func loadInitialItems_when_no_items_then_state_is_loaded_empty() async throws {
            // Given
            let itemProvider = MockPOSItemProvider()
            itemProvider.shouldReturnZeroItems = true
            let sut = PointOfSaleAggregateModel(itemProvider: itemProvider,
                                                cardPresentPaymentService: MockCardPresentPaymentService(),
                                                orderService: MockPOSOrderService())

            try #require(sut.itemListState == .initialLoading)

            // When
            await sut.loadInitialItems()

            // Then
            #expect(sut.itemListState == .empty)
        }

        @Test func loadInitialItems_when_itemProvider_throws_error_then_state_is_error() async throws {
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

        @Test func loadNextItems_when_itemProvider_throws_error_then_state_is_error() async throws {
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

        @Test func loadNextItems_after_itemProvider_throws_error_then_the_same_page_is_requested_next() async throws {
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

        @Test func reload_results_in_state_loaded_with_expected_items() async throws {
            // Given
            try #require(sut.itemListState == .initialLoading)
            let expectedItems = MockPOSItemProvider.makeInitialItems()

            // When
            await sut.reload()

            // Then
            #expect(sut.itemListState == .loaded(expectedItems))
        }

        @Test func reload_requests_first_page() async throws {
            // Given
            await sut.loadNextItems()
            try #require(itemProvider.spyLastRequestedPageNumber == 2)

            // When
            await sut.reload()

            // Then
            #expect(itemProvider.spyLastRequestedPageNumber == 1)
        }

        @Test func reload_when_itemProvider_throws_error_then_state_is_error() async throws {
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
    }

    struct CartTests {
        let sut: PointOfSaleAggregateModel
        private let analytics: WooAnalytics!
        private let analyticsProvider: MockAnalyticsProvider!

        init() {
            analyticsProvider = MockAnalyticsProvider()
            analytics = WooAnalytics(analyticsProvider: analyticsProvider)
            sut = PointOfSaleAggregateModel(itemProvider: MockPOSItemProvider(),
                                            cardPresentPaymentService: MockCardPresentPaymentService(),
                                            orderService: MockPOSOrderService(),
                                            analytics: analytics)
        }

        @Test func addItem_results_in_a_non_empty_cart() async throws {
            // Given
            try #require(sut.cart.isEmpty)
            let item = makeItem()

            // When
            sut.addToCart(item)

            // Then
            #expect(sut.cart.isNotEmpty)
        }

        @Test func addItem_puts_new_items_first_in_the_cart() async throws {
            // Given
            let items = [makeItem(), makeItem(), makeItem()]

            // When
            items.forEach(sut.addToCart(_:))

            // Then
            #expect(sut.cart.map(\.item.itemID) == items.reversed().map(\.itemID))
        }

        @Test func removeItem_after_adding_two_items_removes_item_correctly() async throws {
            // Given
            let item = makeItem(name: "Item 1")
            let anotherItem = makeItem(name: "Item 2")

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
            let item = makeItem(name: "Item 1")
            let anotherItem = makeItem(name: "Item 2")

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
            let item = makeItem()

            // When
            sut.addToCart(item)

            // Then
            let event = try #require(analyticsProvider.receivedEvents.first)
            #expect(event == "pos_item_added_to_cart")
        }
    }

    struct OrderTests {
        private let cardPresentPaymentService = MockCardPresentPaymentService()
        private let itemProvider = MockPOSItemProvider()
        private let orderService = MockPOSOrderService()
        private let sut: PointOfSaleAggregateModel

        init() {
            orderService.orderToReturn = Order.fake()

            sut = PointOfSaleAggregateModel(
                itemProvider: itemProvider,
                cardPresentPaymentService: cardPresentPaymentService,
                orderService: orderService)

            sut.addToCart(makeItem())
        }

        @Test func startNewCart_sets_orderState_to_idle() async throws {
            // Given
            await sut.checkOut()
            try #require(sut.orderState == .loaded(.init(
                cartTotal: "$0.00",
                orderTotal: "",
                taxTotal: "")))

            // When
            sut.startNewCart()

            // Then
            #expect(sut.orderState == .idle)
        }

        @Test func checkOut_when_reader_connects_collectPayment_called() async throws {
            // Given
            cardPresentPaymentService.connectedReader = nil
            await sut.checkOut()
            cardPresentPaymentService.collectPaymentWasCalled = false

            // When
            // `await confirmation` callback only waits until this completes, not until some timeout.
            // Since this is synchonous but triggers async combine behaviour, we can't use that approach.
            cardPresentPaymentService.connectedReader = .init(name: "Test reader", batteryLevel: 0.7)

            // Then
            let timeout = ContinuousClock.now + .seconds(1)

            while cardPresentPaymentService.collectPaymentWasCalled != true {
                try! await Task.sleep(for: .milliseconds(1))
                try #require(.now < timeout)
            }
        }

        @Test func checkOut_when_reader_is_already_connected_collectPayment_called() async throws {
            // Given
            cardPresentPaymentService.connectedReader = .init(name: "Test reader", batteryLevel: 0.7)
            orderService.orderToReturn = Order.fake().copy(items: [.fake()])

            // When
            await sut.checkOut()

            // Then
            #expect(cardPresentPaymentService.collectPaymentWasCalled)
        }

        @Test func after_disconnection_when_reader_reconnects_collectPayment_called() async throws {
            // Given
            cardPresentPaymentService.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
            sut.observeReaderReconnection()
            await sut.checkOut()
            await cardPresentPaymentService.disconnectReader()
            cardPresentPaymentService.collectPaymentWasCalled = false

            // When
            // `await confirmation` callback only waits until this completes, not until some timeout.
            // Since this is synchonous but triggers async combine behaviour, we can't use that approach.
            cardPresentPaymentService.connectedReader = .init(name: "Test reader", batteryLevel: 0.7)

            // Then
            let timeout = ContinuousClock.now + .seconds(1)

            while cardPresentPaymentService.collectPaymentWasCalled != true {
                try! await Task.sleep(for: .milliseconds(1))
                try #require(.now < timeout)
            }
        }

        @Test func checkOut_with_no_previous_order_sets_orderState_syncing_then_loaded() async throws {
            // Given
            var cancellables = Set<AnyCancellable>()
            var orderStates: [PointOfSaleOrderState] = []
            await confirmation() { confirmation in
                // We can use `withObservationTracking` when we move to @Observable
                sut.$orderState.collect(3)
                    .sink { orderState in
                        orderStates.append(contentsOf: orderState)
                        confirmation()
                    }
                    .store(in: &cancellables)

                // When
                await sut.checkOut()
            }

            // Then
            #expect(orderStates == [.idle, .syncing, .loaded(.init(cartTotal: "$0.00", orderTotal: "", taxTotal: ""))])
        }

        @Test func checkOut_with_order_sync_failure_sets_orderState_syncing_then_error() async throws {
            // Given
            orderService.orderToReturn = nil

            var cancellables = Set<AnyCancellable>()
            var orderStates: [PointOfSaleOrderState] = []
            await confirmation() { confirmation in
                // We can use `withObservationTracking` when we move to @Observable
                sut.$orderState.collect(3)
                    .sink { orderState in
                        orderStates.append(contentsOf: orderState)
                        confirmation()
                    }
                    .store(in: &cancellables)

                // When
                await sut.checkOut()
            }

            // Then
            #expect(orderStates == [.idle, .syncing, .error(.init(message: "", handler: {}))])
        }
    }

    struct PaymentTests {
        private let cardPresentPaymentService = MockCardPresentPaymentService()
        private let sut: PointOfSaleAggregateModel

        init() {
            sut = PointOfSaleAggregateModel(
                itemProvider: MockPOSItemProvider(),
                cardPresentPaymentService: cardPresentPaymentService,
                orderService: MockPOSOrderService())
        }


    }
}

private func makeItem(name: String = "") -> POSItem {
    return POSProduct(itemID: UUID(),
                      productID: 0,
                      name: name,
                      price: "",
                      formattedPrice: "",
                      itemCategories: [],
                      productImageSource: nil,
                      productType: .simple)
}
