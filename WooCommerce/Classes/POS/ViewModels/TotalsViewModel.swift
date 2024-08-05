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
    enum PaymentState {
        case idle
        case acceptingCard
        case validatingOrder
        case preparingReader
        case processingPayment
        case cardPaymentSuccessful
    }

    @Published var showsCardReaderSheet: Bool = false
    @Published private(set) var cardPresentPaymentEvent: CardPresentPaymentEvent = .idle
    @Published private(set) var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    @Published private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    @Published private(set) var isShowingCardReaderStatus: Bool = false
    @Published private(set) var isShowingTotalsFields: Bool = false

    @Published private(set) var order: Order? = nil
    private var totalsCalculator: OrderTotalsCalculator? = nil
    @Published private(set) var paymentState: PaymentState

    @Published private(set) var isSyncingOrder: Bool

    @Published private(set) var connectionStatus: CardReaderConnectionStatus = .disconnected

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

    private var startPaymentOnReaderConnection: AnyCancellable?

    func checkOutTapped(with cartItems: [CartItem], allItems: [POSItem]) {
        Task { @MainActor in
            await startSyncingOrder(with: cartItems, allItems: allItems)
        }
    }

    private func startSyncingOrder(with cartItems: [CartItem], allItems: [POSItem]) async {
        guard CartItem.areOrderAndCartDifferent(order: order, cartItems: cartItems) else {
            await startPaymentWhenReaderConnected()
            return
        }
        // calculate totals and sync order if there was a change in the cart
        await syncOrder(for: cartItems, allItems: allItems)
    }

    func connectReaderTapped() {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            do {
                let _ = try await cardPresentPaymentService.connectReader(using: .bluetooth)
            } catch {
                DDLogError("🔴 POS reader connection error: \(error)")
            }
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
        startPaymentOnReaderConnection?.cancel()
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
            let syncedOrder = try await orderService.syncOrder(cart: cart, order: order, allProducts: allItems)
            self.updateOrder(syncedOrder)
            isSyncingOrder = false
            await startPaymentWhenReaderConnected()
            DDLogInfo("🟢 [POS] Synced order: \(syncedOrder)")
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
}

private extension TotalsViewModel {
    func observeConnectedReaderForStatus() {
        cardPresentPaymentService.connectedReaderPublisher
            .map { connectedReader in
                connectedReader == nil ? .disconnected: .connected
            }
            .assign(to: &$connectionStatus)

        Publishers.CombineLatest4($connectionStatus, $isSyncingOrder, $cardPresentPaymentInlineMessage, $order)
            .map { connectionStatus, isSyncingOrder, message, order in
                guard order != nil,
                        !isSyncingOrder
                        else {
                    // When the order's being created or synced, we only show the shimmering totals.
                    // Before the order exists, we don’t want to show the card payment status, as it will
                    // show for a second initially, then disappear the moment we start syncing the order.
                    return false
                }

                switch connectionStatus {
                case .connected:
                    return message != nil
                case .disconnected:
                    // Since the reader is disconnected, this will show the "Connect your reader" CTA button view.
                    return true
                }
            }
            .assign(to: &$isShowingCardReaderStatus)
    }

    func startPaymentWhenReaderConnected() async {
        guard connectionStatus == .connected else {
            return startPaymentOnReaderConnection = $connectionStatus.filter { $0 == .connected }
                .removeDuplicates()
                .sink { _ in
                    Task { @MainActor [weak self] in
                        await self?.collectPayment()
                    }
                }
        }
        await collectPayment()
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

        paymentStatePublisher
            .map {
                $0 != .processingPayment && $0 != .cardPaymentSuccessful
            }
            .assign(to: &$isShowingTotalsFields)
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
        case .show(.displayReaderMessage):
            self = .processingPayment
        case .show(.paymentSuccess):
            self = .cardPaymentSuccessful
        default:
            return nil
        }
    }
}
