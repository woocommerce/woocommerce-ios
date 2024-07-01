import SwiftUI
import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.POSItem
import struct Yosemite.Order
import struct Yosemite.POSCartItem
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
    @Published private(set) var formattedCartTotalPrice: String?

    @Published private(set) var paymentState: PaymentState = .acceptingCard

    @Published private var connectionStatus: CardReaderConnectionStatus = .disconnected

    private let orderService: POSOrderServiceProtocol
    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let currencyFormatter: CurrencyFormatter

    var formattedOrderTotalPrice: String? {
        formattedPrice(order?.total, currency: order?.currency)
    }

    var formattedOrderTotalTaxPrice: String? {
        formattedPrice(order?.totalTax, currency: order?.currency)
    }

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

    init(orderService: POSOrderServiceProtocol,
         cardPresentPaymentService: CardPresentPaymentFacade,
         currencyFormatter: CurrencyFormatter) {
        self.orderService = orderService
        self.cardPresentPaymentService = cardPresentPaymentService
        self.currencyFormatter = currencyFormatter

        observeConnectedReaderForStatus()
        observeCardPresentPaymentEvents()
    }

    func formattedPrice(_ price: String?, currency: String?) -> String? {
        guard let price, let currency else {
            return nil
        }
        // TODO:
        // Remove ServiceLocator dependency. Inject from the app through point of entry
        return CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).formatAmount(price, with: currency)
    }

    func startSyncOrder() {
        // TODO: 
        // Start & stop methods may no longer be needed, since sync state it's only internal
        isSyncingOrder = true
    }

    func stopSyncOrder() {
        isSyncingOrder = false
    }

    func clearOrder() {
        order = nil
    }

    func setOrder(updatedOrder: POSOrder) {
        order = updatedOrder
    }

    func calculateAmountsTapped(with cartItems: [CartItem], allItems: [POSItem]) {
        startSyncingOrder(with: cartItems, allItems: allItems)
    }

    func startSyncingOrder(with cartItems: [CartItem], allItems: [POSItem]) {
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
    }

    @MainActor
    func onTotalsViewDisappearance() {
        cardPresentPaymentService.cancelPayment()
    }
}

private extension TotalsViewModel {
    @MainActor
    func syncOrder(for cartProducts: [CartItem], allItems: [POSItem]) async {
        guard isSyncingOrder == false else {
            return
        }
        startSyncOrder()
        let cart = cartProducts
            .map {
                POSCartItem(itemID: nil,
                            product: $0.item,
                            quantity: Decimal($0.quantity))
            }
        defer {
            stopSyncOrder()
        }
        
        do {
            startSyncOrder()
            let order = try await orderService.syncOrder(cart: cart,
                                                         order: order,
                                                         allProducts: allItems)
            setOrder(updatedOrder: order)
            stopSyncOrder()
            // TODO: this is temporary solution
            // TODO: Move card present here as well.
            // await prepareConnectedReaderForPayment()
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
            return CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).formatAmount(totalValue)
        }(cartItems)
    }
}

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
