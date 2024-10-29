import Foundation
import Combine

import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.POSItem
import protocol Yosemite.POSItemProvider
import struct Yosemite.Order
import struct Yosemite.OrderItem
import struct Yosemite.POSCartItem

import protocol WooFoundation.Analytics

final class PointOfSaleAggregateModel: ObservableObject {

    enum OrderStage {
        case building
        case finalizing
    }

    @Published private(set) var orderStage: OrderStage = .building
    @Published private(set) var allItems: [POSItem] = []
    @Published private(set) var cart: [CartItem] = []
    @Published private(set) var orderState: PointOfSaleOrderState = .idle
    @Published private(set) var order: Order? = nil
    @Published private(set) var connectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected
    @Published private(set) var paymentState: PointOfSalePaymentState = .acceptingCard

    private let orderService: POSOrderServiceProtocol
    let cardPresentPaymentService: CardPresentPaymentFacade
    private let itemProvider: POSItemProvider
    private let analytics: Analytics

    private var cancellables: Set<AnyCancellable> = []
    private var startPaymentOnReaderConnection: AnyCancellable?
    private var cardReaderDisconnection: AnyCancellable?

    init(itemProvider: POSItemProvider,
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderService: POSOrderServiceProtocol,
         analytics: Analytics) {
        self.itemProvider = itemProvider
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderService = orderService
        self.analytics = analytics
        observeCartItemsToCheckIfCartIsEmpty()
        observeCardPresentPaymentEvents()
        observeReaderConnectionStatus()
    }

    private func observeCartItemsToCheckIfCartIsEmpty() {
        $cart
            .filter { $0.isEmpty }
            .sink { [weak self] _ in
                self?.orderStage = .building
            }
            .store(in: &cancellables)
    }

    @MainActor
    func loadItems(pageNumber: Int) async throws {
        let newItems = try await itemProvider.providePointOfSaleItems(pageNumber: pageNumber)
        let uniqueNewItems = newItems.filter { newItem in
            !allItems.contains(where: { $0.productID == newItem.productID })
        }

        allItems.append(contentsOf: uniqueNewItems)
    }

    func removeAllItems() {
        allItems.removeAll()
    }

    func startNewOrder() {
        clearOrder()
        removeAllItemsFromCart()
        orderStage = .building
        paymentState = .acceptingCard
    }

    func editOrder() {
        orderStage = .building
        paymentState = .idle
    }

    func selected(item: POSItem) {
        let cartItem = CartItem(id: UUID(), item: item, quantity: 1)
        addItemToCart(cartItem)
        analytics.track(.pointOfSaleAddItemToCart)
    }

    func addItemToCart(_ item: CartItem) {
        cart.insert(item, at: 0)
    }

    func removeItemFromCart(_ cartItem: CartItem) {
        cart.removeAll(where: { $0.id == cartItem.id })
    }

    func removeAllItemsFromCart() {
        cart.removeAll()
    }

    @MainActor
    func submitCart() async {
        orderStage = .finalizing
        await startSyncingOrder(with: cart, allItems: allItems)
    }

    private func startSyncingOrder(with cartItems: [CartItem], allItems: [POSItem]) async {
        guard CartItem.areOrderAndCartDifferent(order: order, cartItems: cartItems) else {
            await startPaymentWhenReaderConnected()
            return
        }
        // calculate totals and sync order if there was a change in the cart
        await syncOrder(for: cartItems, allItems: allItems)
    }

    func addMoreToCart() {
        orderStage = .building
    }
}

// MARK: - Order syncing

extension PointOfSaleAggregateModel {
    @MainActor
    func syncOrder(for cartProducts: [CartItem], allItems: [POSItem]) async {
        guard orderState.isSyncing == false else {
            return
        }
        orderState = .syncing
        let cart = cartProducts.map {
            POSCartItem(itemID: nil, product: $0.item, quantity: Decimal($0.quantity))
        }

        do {
            let syncedOrder = try await orderService.syncOrder(cart: cart, order: order, allProducts: allItems)
            order = syncedOrder
            orderState = .loaded
            await startPaymentWhenReaderConnected()
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

    private func clearOrder() {
        order = nil
    }
}

// MARK: - Payment collection

extension PointOfSaleAggregateModel {
    func observeReaderConnectionStatus() {
        cardPresentPaymentService.readerConnectionStatusPublisher
            .assign(to: &$connectionStatus)
    }

    func observeCardPresentPaymentEvents() {
        cardPresentPaymentService.paymentEventPublisher
            .compactMap { paymentEvent in
                return PointOfSalePaymentState(from: paymentEvent) }
            .assign(to: &$paymentState)
    }

    func connectReader() {
        guard connectionStatus == .disconnected else {
            return
        }
        Task { @MainActor in
            do {
                let _ = try await cardPresentPaymentService.connectReader(using: .bluetooth)
            } catch {
                DDLogError("🔴 POS reader connection error: \(error)")
            }
        }
    }

    func disconnectReader() {
        guard case .connected = connectionStatus else {
            return
        }
        Task { @MainActor in
            await cardPresentPaymentService.disconnectReader()
        }
    }

    @MainActor
    func collectPayment() async {
        guard let order else {
            return
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

    /// Starts a payment immediately if a reader is connected.
    /// Otherwise, schedules a payment to start the next time a reader connects.
    /// Note that any schedlued payments are cancelled by `cancelReaderPreparation` when the TotalsView goes offscreen.
    func startPaymentWhenReaderConnected() async {
        guard case .connected = connectionStatus else {
            return startPaymentOnReaderConnection = $connectionStatus
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

    func observeReaderReconnection() {
        cardReaderDisconnection = $connectionStatus
            .filter({ $0 == .disconnected })
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.startPaymentWhenReaderConnected()
                }
            }
    }

    func cancelReaderPreparation() {
        cardPresentPaymentService.cancelPayment()
        startPaymentOnReaderConnection?.cancel()
        cardReaderDisconnection?.cancel()
    }

    func cancelThenCollectPayment() {
        cardPresentPaymentService.cancelPayment()
        Task { [weak self] in
            await self?.collectPayment()
        }
    }
}
