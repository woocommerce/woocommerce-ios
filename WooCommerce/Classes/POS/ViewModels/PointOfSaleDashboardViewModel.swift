import SwiftUI
import protocol Yosemite.POSItem
import protocol Yosemite.POSItemProvider
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import protocol Yosemite.POSOrderServiceProtocol
import struct Yosemite.POSOrder
import Combine
import enum Yosemite.OrderStatusEnum
import struct Yosemite.POSCartItem
import struct Yosemite.Order

final class PointOfSaleDashboardViewModel: ObservableObject {
    enum PaymentState {
        case idle
        case acceptingCard
        case preparingReader
        case processingPayment
        case cardPaymentSuccessful

        init?(from cardPaymentEvent: CardPresentPaymentEvent) {
            switch cardPaymentEvent {
            case .idle:
                self = .idle
            case .show(.validatingOrder):
                self = .preparingReader
            case .show(.tapSwipeOrInsertCard):
                self = .acceptingCard
            case .show(.processing):
                self = .processingPayment
            case .show(.paymentSuccess):
                self = .cardPaymentSuccessful
            default:
                return nil
            }
        }
    }

    @ObservedObject var cartViewModel: CartViewModel = CartViewModel()

    @Published private(set) var items: [POSItem] = []

    // Total amounts
    @Published private(set) var formattedCartTotalPrice: String?
    var formattedOrderTotalPrice: String? {
        return formattedPrice(order?.total, currency: order?.currency)
    }
    var formattedOrderTotalTaxPrice: String? {
        return formattedPrice(order?.totalTax, currency: order?.currency)
    }

    private func formattedPrice(_ price: String?, currency: String?) -> String? {
        guard let price, let currency else {
            return nil
        }
        return currencyFormatter.formatAmount(price, with: currency)
    }

    @Published var showsCardReaderSheet: Bool = false
    @Published private(set) var cardPresentPaymentEvent: CardPresentPaymentEvent = .idle
    @Published private(set) var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    @Published private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    let cardReaderConnectionViewModel: CardReaderConnectionViewModel

    @Published private(set) var paymentState: PointOfSaleDashboardViewModel.PaymentState = .acceptingCard
    @Published private(set) var isAddMoreDisabled: Bool = false
    @Published var isExitPOSDisabled: Bool = false

    /// Order created the first time the checkout is shown for a given transaction.
    /// If the merchant goes back to the product selection screen and makes changes, this should be updated when they return to the checkout.
    @Published private var order: POSOrder?
    @Published private(set) var isSyncingOrder: Bool = false
    @Published private(set) var isSyncingItems: Bool = true

    private let orderService: POSOrderServiceProtocol
    private let itemProvider: POSItemProvider
    private let cardPresentPaymentService: CardPresentPaymentFacade

    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

    init(itemProvider: POSItemProvider,
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderService: POSOrderServiceProtocol) {
        self.itemProvider = itemProvider
        self.cardPresentPaymentService = cardPresentPaymentService
        self.cardReaderConnectionViewModel = CardReaderConnectionViewModel(cardPresentPayment: cardPresentPaymentService)
        self.orderService = orderService

        observeCardPresentPaymentEvents()
        observeItemsInCartForCartTotal()
        observePaymentStateForButtonDisabledProperties()
    }

    @MainActor
    func populatePointOfSaleItems() async {
        isSyncingItems = true
        do {
            items = try await itemProvider.providePointOfSaleItems()
        } catch {
            DDLogError("Error on load while fetching product data: \(error)")
        }
        isSyncingItems = false
    }

    @MainActor
    func reload() async {
        isSyncingItems = true
        do {
            let newItems = try await itemProvider.providePointOfSaleItems()
            // Only clears in-memory items if the `do` block continues, otherwise we keep them in memory.
            items.removeAll()
            items = newItems
        } catch {
            DDLogError("Error on reload while updating product data: \(error)")
        }
        isSyncingItems = false
    }

    func submitCart() {
        cartViewModel.submitCart()
        startSyncingOrder()
    }

    var areAmountsFullyCalculated: Bool {
        return isSyncingOrder == false && formattedOrderTotalTaxPrice != nil && formattedOrderTotalPrice != nil
    }

    var showRecalculateButton: Bool {
        return !areAmountsFullyCalculated && isSyncingOrder == false
    }

    func cardPaymentTapped() {
        Task { @MainActor in
            await collectPayment()
        }
    }

    @MainActor
    private func collectPayment() async {
        guard let order else {
            return
        }
        do {
            let finalOrder = orderService.order(from: order)
            try await collectPayment(for: finalOrder)
        } catch {
            DDLogError("Error taking payment: \(error)")
        }
    }

    @MainActor
    private func collectPayment(for order: Order) async throws {
        let paymentResult = try await cardPresentPaymentService.collectPayment(for: order, using: .bluetooth)
    }

    @MainActor
    private func prepareConnectedReaderForPayment() async {
        // Digging in to the connection viewmodel here is a bit of a shortcut, we should improve this.
        // TODO: Have our own subscription to the connected readers
        guard cardReaderConnectionViewModel.connectionStatus == .connected else {
            return
        }
        await collectPayment()
    }

    @MainActor
    func updateOrderStatus(_ status: OrderStatusEnum) async throws -> POSOrder? {
        guard let order else {
            return nil
        }
        let updatedOrder = try await self.orderService.updateOrderStatus(posOrder: order, status: status)
        return updatedOrder
    }

    func calculateAmountsTapped() {
        startSyncingOrder()
    }

    private func startSyncingOrder() {
        Task { @MainActor in
            await syncOrder(for: cartViewModel.itemsInCart)
        }
    }

    func startNewTransaction() {
        // Q: Do we need 2 cart methods if removing all items already implies moving to .building state?
        cartViewModel.removeAllItemsFromCart()
        cartViewModel.startNewTransaction()
        paymentState = .acceptingCard
        order = nil
    }

    @MainActor
    func onTotalsViewDisappearance() {
        cardPresentPaymentService.cancelPayment()
    }
}

private extension PointOfSaleDashboardViewModel {
    func observeItemsInCartForCartTotal() {
        cartViewModel.$itemsInCart
            .map { [weak self] in
                guard let self else { return "-" }
                let totalValue: Decimal = $0.reduce(0) { partialResult, cartItem in
                    let itemPrice = self.currencyFormatter.convertToDecimal(cartItem.item.price) ?? 0
                    let quantity = cartItem.quantity
                    let total = itemPrice.multiplying(by: NSDecimalNumber(value: quantity)) as Decimal
                    return partialResult + total
                }
                return currencyFormatter.formatAmount(totalValue)
            }
            .assign(to: &$formattedCartTotalPrice)
    }

    func observeCardPresentPaymentEvents() {
        cardPresentPaymentService.paymentEventPublisher.assign(to: &$cardPresentPaymentEvent)
        cardPresentPaymentService.paymentEventPublisher
            .map { event -> PointOfSaleCardPresentPaymentAlertType? in
                guard case let .show(eventDetails) = event,
                      case let .alert(alertType) = eventDetails.pointOfSalePresentationStyle else {
                    return nil
                }
                return alertType
            }
            .assign(to: &$cardPresentPaymentAlertViewModel)
        cardPresentPaymentService.paymentEventPublisher
            .map { event -> PointOfSaleCardPresentPaymentMessageType? in
                guard case let .show(eventDetails) = event,
                      case let .message(messageType) = eventDetails.pointOfSalePresentationStyle else {
                    return nil
                }
                return messageType
            }
            .assign(to: &$cardPresentPaymentInlineMessage)
        cardPresentPaymentService.paymentEventPublisher.map { event in
            switch event {
            case .idle:
                return false
            case .show(let eventDetails):
                switch eventDetails.pointOfSalePresentationStyle {
                case .alert:
                    return true
                case .message, .none:
                    return false
                }
            case .showOnboarding:
                return true
            }
        }.assign(to: &$showsCardReaderSheet)
        cardPresentPaymentService.paymentEventPublisher
            .compactMap({ PaymentState(from: $0) })
            .assign(to: &$paymentState)
    }

    func observePaymentStateForButtonDisabledProperties() {
        $paymentState
            .map { paymentState in
                switch paymentState {
                case .processingPayment,
                        .cardPaymentSuccessful:
                    return true
                case .idle,
                        .acceptingCard,
                        .preparingReader:
                    return false
                }
            }
            .assign(to: &$isAddMoreDisabled)

        $paymentState
            .map { paymentState in
                switch paymentState {
                case .processingPayment:
                    return true
                case .idle,
                        .acceptingCard,
                        .preparingReader,
                        .cardPaymentSuccessful:
                    return false
                }
            }
            .assign(to: &$isExitPOSDisabled)
    }

    @MainActor
    private func syncOrder(for cartProducts: [CartItem]) async {
        guard isSyncingOrder == false else {
            return
        }
        isSyncingOrder = true
        let cart = cartProducts
            .map {
                POSCartItem(itemID: nil,
                            product: $0.item,
                            quantity: Decimal($0.quantity))
            }
        defer {
            isSyncingOrder = false
        }
        do {
            isSyncingOrder = true
            let order = try await orderService.syncOrder(cart: cart,
                                                              order: order,
                                                              allProducts: items)
            self.order = order
            isSyncingOrder = false
            // TODO: this is temporary solution
            await prepareConnectedReaderForPayment()
            DDLogInfo("🟢 [POS] Synced order: \(order)")
        } catch {
            DDLogError("🔴 [POS] Error syncing order: \(error)")
        }
    }
}

private extension PointOfSaleDashboardViewModel {
    enum OrderSyncError: Error {
        case selfDeallocated
    }
}
