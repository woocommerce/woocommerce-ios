import Foundation
import Combine

import protocol Yosemite.POSItem
import protocol Yosemite.POSItemProvider
import protocol WooFoundation.Analytics
import struct Yosemite.Order
import struct Yosemite.OrderItem
import protocol Yosemite.POSOrderServiceProtocol
import struct Yosemite.POSCartItem
import class WooFoundation.CurrencyFormatter
import enum Yosemite.POSProductProviderError

protocol PointOfSaleAggregateModelProtocol {
    var orderStage: PointOfSaleOrderStage { get }

    var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus { get }
    func connectCardReader()
    func disconnectCardReader()

    @available(*, deprecated, message: "`allItems` is due for removal, use `itemListState` instead.")
    var allItems: [POSItem] { get }
    var itemListState: ItemListState { get }
    func loadInitialItems() async
    func loadNextItems() async
    func reload() async

    var cart: [CartItem] { get }
    func addToCart(_ item: POSItem)
    func remove(cartItem: CartItem)
    func removeAllItemsFromCart()
    func submitCart() async
    func addMoreToCart()
    func startNewCart()

    var orderState: PointOfSaleOrderState { get }
    func checkOut() async
}

class PointOfSaleAggregateModel: ObservableObject, PointOfSaleAggregateModelProtocol {
    @Published private(set) var orderStage: PointOfSaleOrderStage = .building

    @Published private(set) var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected

    @Published private(set) var allItems: [POSItem] = []
    @Published private(set) var itemListState: ItemListState = .initialLoading

    @Published private(set) var cart: [CartItem] = []

    @Published private(set) var orderState: PointOfSaleOrderState = .idle

    // We need access to update the order with the customer email, also siteID is retrieved from order.siteID association
    private(set) var order: Order? = nil

    private let itemProvider: POSItemProvider
    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let orderService: POSOrderServiceProtocol
    private let currencyFormatter: CurrencyFormatter
    private let analytics: Analytics

    private var currentPage: Int = Constants.initialPage
    private var mightHaveMorePages: Bool = true
    private var startPaymentOnCardReaderConnection: AnyCancellable?
    private var cardReaderDisconnection: AnyCancellable?

    init(itemProvider: POSItemProvider,
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderService: POSOrderServiceProtocol,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         analytics: Analytics = ServiceLocator.analytics) {
        self.itemProvider = itemProvider
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderService = orderService
        self.currencyFormatter = currencyFormatter
        self.analytics = analytics
        publishCardReaderConnectionStatus()
    }
}

// MARK: - ItemList
extension PointOfSaleAggregateModel {
    @MainActor
    func loadInitialItems() async {
        mightHaveMorePages = true
        itemListState = .initialLoading
        try? await load(pageNumber: Constants.initialPage)
    }

    @MainActor
    func loadNextItems() async {
        do {
            guard mightHaveMorePages else {
                return
            }
            itemListState = .loading(allItems)

            let nextPage = currentPage + 1
            try await load(pageNumber: nextPage)
            currentPage = nextPage
        } catch {
            // No need to do anything; this avoids us incorrectly incrementing currentPage.
        }
    }

    @MainActor
    func reload() async {
        allItems.removeAll()
        currentPage = Constants.initialPage
        mightHaveMorePages = true
        itemListState = .loading(allItems)
        try? await load(pageNumber: currentPage)
    }

    @MainActor
    private func load(pageNumber: Int) async throws {
        do {
            try await fetchItems(pageNumber: pageNumber)

            mightHaveMorePages = true
            updateItemListStateAfterLoadAttempt()
        } catch POSProductProviderError.pageOutOfRange {
            mightHaveMorePages = false
            updateItemListStateAfterLoadAttempt()
            throw POSProductProviderError.pageOutOfRange
        } catch {
            itemListState = .error(PointOfSaleErrorState.errorOnLoadingProducts())
            throw error
        }
    }

    @MainActor
    private func fetchItems(pageNumber: Int) async throws {
        let newItems = try await itemProvider.providePointOfSaleItems(pageNumber: pageNumber)
        let uniqueNewItems = newItems.filter { newItem in
            !allItems.contains(where: { $0.productID == newItem.productID })
        }
        allItems.append(contentsOf: uniqueNewItems)
    }

    private func updateItemListStateAfterLoadAttempt() {
        if allItems.count == 0 {
            itemListState = .empty
        } else {
            itemListState = .loaded(allItems)
        }
    }
}

// MARK: - Cart

extension PointOfSaleAggregateModel {
    func addToCart(_ item: POSItem) {
        cart.insert(CartItem(id: UUID(), item: item, quantity: 1), at: 0)
        Task { @MainActor in
            analytics.track(.pointOfSaleAddItemToCart)
        }
    }

    func remove(cartItem: CartItem) {
        cart.removeAll(where: { $0.id == cartItem.id } )
    }

    func removeAllItemsFromCart() {
        cart.removeAll()
    }

    @MainActor
    func submitCart() async {
        orderStage = .finalizing
        await checkOut()
    }

    func addMoreToCart() {
        orderStage = .building
    }

    func startNewCart() {
        removeAllItemsFromCart()
        clearOrder()
        orderStage = .building
    }
}

// MARK: - Card payments

extension PointOfSaleAggregateModel {
    private func publishCardReaderConnectionStatus() {
        // When adopting Observable, we can use `assign(to: on:)` here instead
        cardPresentPaymentService.readerConnectionStatusPublisher.assign(to: &$cardReaderConnectionStatus)
    }

    func connectCardReader() {
        Task { @MainActor in
            _ = try await cardPresentPaymentService.connectReader(using: .bluetooth)
        }
    }

    func disconnectCardReader() {
        Task { @MainActor in
            await cardPresentPaymentService.disconnectReader()
        }
    }

    /// Starts a payment immediately if a reader is connected.
    /// Otherwise, schedules a payment to start the next time a reader connects.
    /// Note that any schedlued payments are cancelled by `cancelReaderPreparation`
    /// e.g. when the TotalsView goes offscreen.
    func startPaymentWhenCardReaderConnected() async {
        guard case .connected = cardReaderConnectionStatus else {
            return startPaymentOnCardReaderConnection = $cardReaderConnectionStatus
                .filter { status in
                    switch status {
                    case .connected:
                        return true
                    case .disconnected, .disconnecting, .cancellingConnection:
                        return false
                    }
                }
                .removeDuplicates()
                .sink { _ in
                    Task { @MainActor [weak self] in
                        await self?.collectPayment()
                    }
                }
        }
        await collectPayment()
    }

    @MainActor
    func collectPayment() async {
        guard let order else {
            return
            // Should this throw?
        }
        do {
            try await collectPayment(for: order)
        } catch {
            DDLogError("Error taking payment: \(error)")
        }
    }

    @MainActor
    private func collectPayment(for order: Order) async throws {
        _ = try await cardPresentPaymentService.collectPayment(for: order, using: .bluetooth)
    }

    func cancelThenCollectPayment() {
        cardPresentPaymentService.cancelPayment()
        Task { [weak self] in
            await self?.collectPayment()
        }
    }

    func cancelCardReaderPreparation() {
        cardPresentPaymentService.cancelPayment()
        startPaymentOnCardReaderConnection?.cancel()
        cardReaderDisconnection?.cancel()
    }

    func observeReaderReconnection() {
        cardReaderDisconnection = $cardReaderConnectionStatus
            .filter({ $0 == .disconnected })
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.startPaymentWhenCardReaderConnected()
                }
            }
    }
}

// MARK: - Order syncing

extension PointOfSaleAggregateModel {
    func checkOut() async {
        guard CartItem.areOrderAndCartDifferent(order: order, cartItems: cart) else {
            await startPaymentWhenCardReaderConnected()
            return
        }
        // calculate totals and sync order if there was a change in the cart
        await syncOrder(for: cart, allItems: allItems)
    }

    @MainActor
    private func syncOrder(for cartProducts: [CartItem], allItems: [POSItem]) async {
        guard orderState.isSyncing == false else {
            return
        }
        orderState = .syncing
        let cart = cartProducts.map {
            POSCartItem(itemID: nil, product: $0.item, quantity: Decimal($0.quantity))
        }

        do {
            let syncedOrder = try await orderService.syncOrder(cart: cart, order: order, allProducts: allItems)
            self.order = syncedOrder
            orderState = .loaded(totals(for: syncedOrder))
            await startPaymentWhenCardReaderConnected()
            DDLogInfo("🟢 [POS] Synced order: \(syncedOrder)")
        } catch {
            DDLogError("🔴 [POS] Error syncing order: \(error)")

            // Consider removing error or handle specific errors with our own formatting and localization
            orderState = .error(.init(message: error.localizedDescription, handler: { [weak self] in
                Task {
                    await self?.syncOrder(for: cartProducts, allItems: allItems)
                }
            }))
        }
    }

    func clearOrder() {
        order = nil
        orderState = .idle
    }
}

// MARK: - Price formatters

private extension PointOfSaleAggregateModel {
    func totals(for order: Order) -> PointOfSaleOrderTotals {
        let totalsCalculator = OrderTotalsCalculator(for: order,
                                                     using: currencyFormatter)
        return PointOfSaleOrderTotals(
            cartTotal: formattedPrice(totalsCalculator.itemsTotal.stringValue,
                                      currency: order.currency) ?? "",
            orderTotal: formattedPrice(order.total, currency: order.currency) ?? "",
            taxTotal: formattedPrice(order.totalTax, currency: order.currency) ?? "")
    }

    func formattedPrice(_ price: String?, currency: String?) -> String? {
        guard let price, let currency else {
            return nil
        }
        return currencyFormatter.formatAmount(price, with: currency)
    }
}

private extension PointOfSaleAggregateModel {
    enum Constants {
        static let initialPage: Int = 1
    }
}

struct PointOfSaleErrorState: Equatable {
    let title: String
    let subtitle: String
    let buttonText: String

    static func errorOnLoadingProducts() -> Self {
        PointOfSaleErrorState(title: Constants.failedToLoadTitle,
                              subtitle: Constants.failedToLoadSubtitle,
                              buttonText: Constants.failedToLoadButtonTitle)
    }

    enum Constants {
        static let failedToLoadTitle = NSLocalizedString(
            "pos.itemList.failedToLoadTitle",
            value: "Error loading products",
            comment: "Text appearing on the item list screen when there's an error loading products."
        )
        static let failedToLoadSubtitle = NSLocalizedString(
            "pos.itemList.failedToLoadSubtitle",
            value: "Give it another go?",
            comment: "Text appearing on the item list screen as subtitle when there's an error loading products."
        )
        static let failedToLoadButtonTitle = NSLocalizedString(
            "pos.itemList.failedToLoadButtonTitle",
            value: "Retry",
            comment: "Text for the button appearing on the item list screen when there's an error loading products."
        )
    }
}
