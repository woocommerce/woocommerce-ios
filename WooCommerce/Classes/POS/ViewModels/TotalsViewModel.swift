import SwiftUI
import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.POSItem
import struct Yosemite.Order
import struct Yosemite.POSCartItem
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrder
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

final class TotalsViewModel: ObservableObject {
    enum PaymentState {
        case idle
        case acceptingCard
        case preparingReader
        case processingPayment
        case cardPaymentSuccessful
    }

    @Published var showsCardReaderSheet: Bool = false
    @Published private(set) var cardPresentPaymentEvent: CardPresentPaymentEvent = .idle
    @Published private(set) var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    @Published private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?

    /// Order created the first time the checkout is shown for a given transaction.
    /// If the merchant goes back to the product selection screen and makes changes, this should be updated when they return to the checkout.
    @Published private(set) var order: POSOrder?
    @Published private(set) var isSyncingOrder: Bool = false

    @Published private(set) var paymentState: PaymentState = .acceptingCard

    @Published private(set) var connectionStatus: CardReaderConnectionStatus = .disconnected

    // MARK: - Order total amounts

    @Published private(set) var formattedCartTotalPrice: String?

    var formattedOrderTotalPrice: String? {
        formattedPrice(order?.total, currency: order?.currency)
    }

    var formattedOrderTotalTaxPrice: String? {
        formattedPrice(order?.totalTax, currency: order?.currency)
    }

    // MARK: - View states

    var showRecalculateButton: Bool {
        !areAmountsFullyCalculated &&
        isSyncingOrder == false
    }

    var areAmountsFullyCalculated: Bool {
        isSyncingOrder == false &&
        formattedOrderTotalTaxPrice != nil &&
        formattedOrderTotalPrice != nil
    }

    var isShimmering: Bool {
        isSyncingOrder
    }

    var isPriceFieldRedacted: Bool {
        formattedOrderTotalTaxPrice == nil || isSyncingOrder
    }

    var isTotalPriceFieldRedacted: Bool {
        formattedOrderTotalPrice == nil || isSyncingOrder
    }

    private let orderService: POSOrderServiceProtocol
    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let currencyFormatter: CurrencyFormatter

    init(orderService: POSOrderServiceProtocol,
         cardPresentPaymentService: CardPresentPaymentFacade,
         currencyFormatter: CurrencyFormatter) {
        self.orderService = orderService
        self.cardPresentPaymentService = cardPresentPaymentService
        self.currencyFormatter = currencyFormatter

        observeConnectedReaderForStatus()
        observeCardPresentPaymentEvents()
    }

    func calculateAmountsTapped(with cartItems: [CartItem], allItems: [POSItem]) {
        startSyncingOrder(with: cartItems, allItems: allItems)
    }

    private func areOrderAndCartDifferent(cartItems: [CartItem]) -> Bool {
        // check if order has same items as cart does
        if let order {
            // first we get list of all products 1 by 1
            var cleanOrderItems: [POSOrderItem] = order.items.flatMap {
                Array(repeating: $0, count: $0.quantity.intValue)
            }
            var cleanCartItems: [POSItem] = cartItems.flatMap {
                Array(repeating: $0.item, count: $0.quantity)
            }
            if cleanOrderItems.count == cleanCartItems.count {
                // sort items by productIDs to have them in same order for comparison
                cleanOrderItems.sort { $0.productID < $1.productID }
                cleanCartItems.sort { $0.productID < $1.productID }
                // check if all the items are same, prices included
                for (index, cartItem) in cleanCartItems.enumerated() {
                    let orderItem = cleanOrderItems[index]
                    if cartItem.productID != orderItem.productID || cartItem.price != orderItem.price.stringValue {
                        return true
                    }
                }
                return false
            }
        }
        return true
    }

    func startSyncingOrder(with cartItems: [CartItem], allItems: [POSItem]) {
        guard areOrderAndCartDifferent(cartItems: cartItems) else {
            return
        }
        // calculate totals and sync order if there was a change in the cart
        Task { @MainActor in
            calculateCartTotal(cartItems: cartItems)
            await syncOrder(for: cartItems, allItems: allItems)
        }
    }

    func cardPaymentTapped() {
        Task { @MainActor in
            await collectPayment()
        }
    }

    func startNewTransaction() {
        paymentState = .acceptingCard
        clearOrder()
        cardPresentPaymentInlineMessage = nil
    }

    @MainActor
    func onTotalsViewDisappearance() {
        cardPresentPaymentService.cancelPayment()
    }
}

// MARK: - Order syncing

extension TotalsViewModel {
    @MainActor
    func syncOrder(for cartProducts: [CartItem], allItems: [POSItem]) async {
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
                                                         allProducts: allItems)
            self.order = order
            isSyncingOrder = false
            // TODO: this is temporary solution
            await prepareConnectedReaderForPayment()
            DDLogInfo("🟢 [POS] Synced order: \(order)")
        } catch {
            DDLogError("🔴 [POS] Error syncing order: \(error)")
        }
    }

    func calculateCartTotal(cartItems: [CartItem]) {
        formattedCartTotalPrice = { cartItems in
            let totalValue: Decimal = cartItems.reduce(0) { partialResult, cartItem in
                let itemPrice = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).convertToDecimal(cartItem.item.price) ?? 0
                let quantity = cartItem.quantity
                let total = itemPrice.multiplying(by: NSDecimalNumber(value: quantity)) as Decimal
                return partialResult + total
            }
            return currencyFormatter.formatAmount(totalValue)
        }(cartItems)
    }

    func formattedPrice(_ price: String?, currency: String?) -> String? {
        guard let price, let currency else {
            return nil
        }
        return currencyFormatter.formatAmount(price, with: currency)
    }
}

extension TotalsViewModel {
    func clearOrder() {
        order = nil
    }
}

// MARK: - Payment collection

private extension TotalsViewModel {
    @MainActor
    func collectPayment() async {
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
    func collectPayment(for order: Order) async throws {
        _ = try await cardPresentPaymentService.collectPayment(for: order, using: .bluetooth)
    }

    @MainActor
    func prepareConnectedReaderForPayment() async {
        guard connectionStatus == .connected else {
            return
        }
        await collectPayment()
    }
}

private extension TotalsViewModel {
    func observeConnectedReaderForStatus() {
        cardPresentPaymentService.connectedReaderPublisher
            .map { connectedReader in
                connectedReader == nil ? .disconnected: .connected
            }
            .assign(to: &$connectionStatus)
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
}

private extension TotalsViewModel.PaymentState {
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
