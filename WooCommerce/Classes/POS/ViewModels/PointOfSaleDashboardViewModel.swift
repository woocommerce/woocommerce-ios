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

    let itemSelectorViewModel: ItemSelectorViewModel
    private(set) lazy var cartViewModel: CartViewModel = CartViewModel(orderStage: $orderStage.eraseToAnyPublisher())
    let totalsViewModel: TotalsViewModel = TotalsViewModel()

    @Published private(set) var isCartCollapsed: Bool = true

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

    enum OrderStage {
        case building
        case finalizing
    }

    @Published private(set) var orderStage: OrderStage = .building

    @Published private(set) var isAddMoreDisabled: Bool = false
    @Published var isExitPOSDisabled: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    // TODO: 12998 - move the following properties to totals view model
    @Published private(set) var paymentState: PointOfSaleDashboardViewModel.PaymentState = .acceptingCard
    private var itemsInCart: [CartItem] = []

    /// Order created the first time the checkout is shown for a given transaction.
    /// If the merchant goes back to the product selection screen and makes changes, this should be updated when they return to the checkout.
    @Published private var order: POSOrder?

    private let orderService: POSOrderServiceProtocol
    private let cardPresentPaymentService: CardPresentPaymentFacade

    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

    init(itemProvider: POSItemProvider,
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderService: POSOrderServiceProtocol) {
        self.cardPresentPaymentService = cardPresentPaymentService
        self.cardReaderConnectionViewModel = CardReaderConnectionViewModel(cardPresentPayment: cardPresentPaymentService)
        self.orderService = orderService

        self.itemSelectorViewModel = .init(itemProvider: itemProvider)

        observeSelectedItemToAddToCart()
        observeCartItemsForCollapsedState()
        observeCartSubmission()
        observeCartAddMoreAction()
        observeCartItemsToCheckIfCartIsEmpty()
        observeCardPresentPaymentEvents()
        observeItemsInCartForCartTotal()
        observePaymentStateForButtonDisabledProperties()
    }

    var areAmountsFullyCalculated: Bool {
        totalsViewModel.isSyncingOrder == false &&
        formattedOrderTotalTaxPrice != nil &&
        formattedOrderTotalPrice != nil
    }

    var showRecalculateButton: Bool {
        !areAmountsFullyCalculated &&
        totalsViewModel.isSyncingOrder == false
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
        _ = try await cardPresentPaymentService.collectPayment(for: order, using: .bluetooth)
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
        // TODO: 12998 - move to the totals view model
        startSyncingOrder(cartItems: itemsInCart)
    }

    private func startSyncingOrder(cartItems: [CartItem]) {
        // TODO: 12998 - move to the totals view model
        // At this point, this should happen in the TotalsViewModel
        Task { @MainActor in
            itemsInCart = cartItems
            await syncOrder(for: cartItems)
        }
    }

    func startNewTransaction() {
        // clear cart
        cartViewModel.removeAllItemsFromCart()
        orderStage = .building
        paymentState = .acceptingCard
        order = nil
    }

    @MainActor
    func onTotalsViewDisappearance() {
        cardPresentPaymentService.cancelPayment()
    }
}

private extension PointOfSaleDashboardViewModel {
    func observeSelectedItemToAddToCart() {
        itemSelectorViewModel.selectedItemPublisher.sink { [weak self] selectedItem in
            self?.cartViewModel.addItemToCart(selectedItem)
        }
        .store(in: &cancellables)
    }

    func observeCartItemsForCollapsedState() {
        cartViewModel.$itemsInCart
            .map { $0.isEmpty }
            .assign(to: &$isCartCollapsed)
    }

    func observeCartSubmission() {
        cartViewModel.cartSubmissionPublisher.sink { [weak self] cartItems in
            guard let self else { return }
            orderStage = .finalizing
            startSyncingOrder(cartItems: cartItems)
        }
        .store(in: &cancellables)
    }

    func observeCartAddMoreAction() {
        cartViewModel.addMoreToCartActionPublisher.sink { [weak self] in
            guard let self else { return }
            orderStage = .building
        }
        .store(in: &cancellables)
    }

    func observeCartItemsToCheckIfCartIsEmpty() {
        cartViewModel.$itemsInCart
            .filter { $0.isEmpty }
            .sink { [weak self] _ in
                self?.orderStage = .building
            }
        .store(in: &cancellables)
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
        guard totalsViewModel.isSyncingOrder == false else {
            return
        }
        totalsViewModel.startSyncOrder()
        let cart = cartProducts
            .map {
                POSCartItem(itemID: nil,
                            product: $0.item,
                            quantity: Decimal($0.quantity))
            }
        defer {
            totalsViewModel.stopSyncOrder()
        }
        do {
            totalsViewModel.startSyncOrder()
            let order = try await orderService.syncOrder(cart: cart,
                                                         order: order,
                                                         allProducts: itemSelectorViewModel.items)
            self.order = order
            totalsViewModel.stopSyncOrder()
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
