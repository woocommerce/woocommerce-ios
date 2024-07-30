import SwiftUI
import Combine
import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.POSItem
import struct Yosemite.Order
import struct Yosemite.OrderItem
import struct Yosemite.POSCartItem
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

final class TotalsViewModel: ObservableObject, TotalsViewModelProtocol {
    var isPriceFieldRedacted: Bool

    enum PaymentState {
        case idle
        case acceptingCard
        case validatingOrder
        case preparingReader
        case processingPayment
        case cardPaymentSuccessful
    }

    @Published var showsCardReaderSheet: Bool = false
    @Published var cardPresentPaymentEvent: CardPresentPaymentEvent = .idle
    @Published var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    @Published private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    @Published private(set) var isShowingCardReaderStatus: Bool = false

    @Published private(set) var order: Order? = nil
    private var totalsCalculator: OrderTotalsCalculator? = nil
    @Published var paymentState: PaymentState

    @Published var isSyncingOrder: Bool

    @Published var connectionStatus: CardReaderConnectionStatus = .disconnected

    @Published var formattedCartTotalPrice: String?
    @Published var formattedOrderTotalPrice: String?
    @Published var formattedOrderTotalTaxPrice: String?

    var computedFormattedCartTotalPrice: String? {
        formattedPrice(totalsCalculator?.itemsTotal.stringValue, currency: order?.currency)
    }

    var computedFormattedOrderTotalPrice: String? {
        formattedPrice(order?.total, currency: order?.currency)
    }

    var computedFormattedOrderTotalTaxPrice: String? {
        formattedPrice(order?.totalTax, currency: order?.currency)
    }

    var showRecalculateButton: Bool {
        !areAmountsFullyCalculated && isSyncingOrder == false
    }

    var areAmountsFullyCalculated: Bool {
        isSyncingOrder == false && formattedOrderTotalTaxPrice != nil && formattedOrderTotalPrice != nil
    }

    var isShimmering: Bool {
        isSyncingOrder
    }

    var isSubtotalFieldRedacted: Bool {
        formattedCartTotalPrice == nil || isSyncingOrder
    }

    var isTaxFieldRedacted: Bool {
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
         currencyFormatter: CurrencyFormatter,
         paymentState: PaymentState,
         isSyncingOrder: Bool) {
        self.orderService = orderService
        self.cardPresentPaymentService = cardPresentPaymentService
        self.currencyFormatter = currencyFormatter
        self.paymentState = paymentState
        self.isSyncingOrder = isSyncingOrder
        self.isPriceFieldRedacted = false
        self.formattedCartTotalPrice = nil
        self.formattedOrderTotalPrice = nil
        self.formattedOrderTotalTaxPrice = nil

        // Initialize all properties before calling methods
        self.observeConnectedReaderForStatus()
        self.observeCardPresentPaymentEvents()
    }

    var isSyncingOrderPublisher: Published<Bool>.Publisher { $isSyncingOrder }
    var paymentStatePublisher: Published<PaymentState>.Publisher { $paymentState }
    var showsCardReaderSheetPublisher: Published<Bool>.Publisher { $showsCardReaderSheet }
    var cardPresentPaymentAlertViewModelPublisher: Published<PointOfSaleCardPresentPaymentAlertType?>.Publisher { $cardPresentPaymentAlertViewModel }
    var cardPresentPaymentEventPublisher: Published<CardPresentPaymentEvent>.Publisher { $cardPresentPaymentEvent }
    var connectionStatusPublisher: Published<CardReaderConnectionStatus>.Publisher { $connectionStatus }
    var formattedCartTotalPricePublisher: Published<String?>.Publisher { $formattedCartTotalPrice }
    var formattedOrderTotalPricePublisher: Published<String?>.Publisher { $formattedOrderTotalPrice }
    var formattedOrderTotalTaxPricePublisher: Published<String?>.Publisher { $formattedOrderTotalTaxPrice }

    func calculateAmountsTapped(with cartItems: [CartItem], allItems: [POSItem]) {
        startSyncingOrder(with: cartItems, allItems: allItems)
    }

    func startSyncingOrder(with cartItems: [CartItem], allItems: [POSItem]) {
        guard CartItem.areOrderAndCartDifferent(order: order, cartItems: cartItems) else {
            Task { @MainActor in
                await prepareConnectedReaderForPayment()
            }
            return
        }
        // calculate totals and sync order if there was a change in the cart
        Task { @MainActor in
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
        let cart = cartProducts.map {
            POSCartItem(itemID: nil, product: $0.item, quantity: Decimal($0.quantity))
        }
        defer {
            isSyncingOrder = false
        }
        do {
            isSyncingOrder = true
            let syncedOrder = try await orderService.syncOrder(cart: cart, order: order, allProducts: allItems)
            self.updateOrder(syncedOrder)
            isSyncingOrder = false
            await prepareConnectedReaderForPayment()
            DDLogInfo("🟢 [POS] Synced order: \(order)")
        } catch {
            DDLogError("🔴 [POS] Error syncing order: \(error)")
        }
    }

    private func updateFormattedPrices() {
        formattedCartTotalPrice = computedFormattedCartTotalPrice
        formattedOrderTotalPrice = computedFormattedOrderTotalPrice
        formattedOrderTotalTaxPrice = computedFormattedOrderTotalTaxPrice
    }

    private func updateOrder(_ updatedOrder: Order) {
        self.order = updatedOrder
        totalsCalculator = OrderTotalsCalculator(for: updatedOrder, using: currencyFormatter)
        updateFormattedPrices()
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
            try await collectPayment(for: order)
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

        Publishers.CombineLatest3($connectionStatus, $isSyncingOrder, $cardPresentPaymentInlineMessage)
            .map { connectionStatus, isSyncingOrder, message in
                if isSyncingOrder {
                    return false
                }

                if connectionStatus == .connected {
                    return message != nil
                }

                return true
            }
            .assign(to: &$isShowingCardReaderStatus)
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
            .compactMap { PaymentState(from: $0) }
            .assign(to: &$paymentState)
    }
}

private extension TotalsViewModel.PaymentState {
    init?(from cardPaymentEvent: CardPresentPaymentEvent) {
        switch cardPaymentEvent {
        case .idle:
            self = .idle
        case .show(.validatingOrder):
            self = .validatingOrder
        case .show(.preparingForPayment):
            self = .preparingReader
        case .show(.tapSwipeOrInsertCard):
            self = .acceptingCard
        case .show(.processing):
            self = .processingPayment
        case .show(.displayReaderMessage(message: _)):
            self = .processingPayment
        case .show(.paymentSuccess):
            self = .cardPaymentSuccessful
        default:
            return nil
        }
    }
}
