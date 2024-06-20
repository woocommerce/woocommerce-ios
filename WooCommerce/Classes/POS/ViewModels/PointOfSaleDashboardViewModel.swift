import SwiftUI
import protocol Yosemite.POSItem
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

final class PointOfSaleDashboardViewModel: ObservableObject {
    enum PaymentState {
        case acceptingCard
        case processingCard
        case cardPaymentSuccessful
    }

    @Published private(set) var items: [POSItem]
    @Published private(set) var itemsInCart: [CartItem] = [] {
        didSet {
            calculateAmounts()
        }
    }
    @Published private(set) var formattedCartTotalPrice: String?
    @Published private(set) var formattedOrderTotalPrice: String?
    @Published private(set) var formattedOrderTotalTaxPrice: String?

    @Published var showsCardReaderSheet: Bool = false
    @Published private(set) var cardPresentPaymentEvent: CardPresentPaymentEvent = .idle
    @Published private(set) var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    @Published private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    let cardReaderConnectionViewModel: CardReaderConnectionViewModel

    @Published var showsCreatingOrderSheet: Bool = false

    enum OrderStage {
        case building
        case finalizing
    }

    @Published private(set) var orderStage: OrderStage = .building

    /// Order created the first time the checkout is shown for a given transaction.
    /// If the merchant goes back to the product selection screen and makes changes, this should be updated when they return to the checkout.
    private var order: Order?

    private let cardPresentPaymentService: CardPresentPaymentFacade

    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

    init(items: [POSItem],
         cardPresentPaymentService: CardPresentPaymentFacade) {
        self.items = items
        self.cardPresentPaymentService = cardPresentPaymentService
        self.cardReaderConnectionViewModel = CardReaderConnectionViewModel(cardPresentPayment: cardPresentPaymentService)
        observeCardPresentPaymentEvents()
        observeItemsInCartForCartTotal()
    }

    var isCartCollapsed: Bool {
        itemsInCart.isEmpty
    }

    var itemToScrollToWhenCartUpdated: CartItem? {
        return itemsInCart.last
    }

    func addItemToCart(_ item: POSItem) {
        let cartItem = CartItem(id: UUID(), item: item, quantity: 1)
        itemsInCart.append(cartItem)
    }

    func removeItemFromCart(_ cartItem: CartItem) {
        itemsInCart.removeAll(where: { $0.id == cartItem.id })
        checkIfCartEmpty()
    }

    var itemsInCartLabel: String? {
        switch itemsInCart.count {
        case 0:
            return nil
        default:
            return String.pluralize(itemsInCart.count,
                                    singular: "%1$d item",
                                    plural: "%1$d items")
        }
    }

    private func checkIfCartEmpty() {
        if itemsInCart.isEmpty {
            orderStage = .building
        }
    }

    func submitCart() {
        // TODO: https://github.com/woocommerce/woocommerce-ios/issues/12810
        orderStage = .finalizing
    }

    func addMoreToCart() {
        orderStage = .building
    }

    private func calculateAmounts() {
        // TODO: this is just a starting point for this logic, to have something calculated on the fly
        if let formattedCartTotalPrice = formattedCartTotalPrice,
           let subtotalAmount = currencyFormatter.convertToDecimal(formattedCartTotalPrice)?.doubleValue {
            let taxAmount = subtotalAmount * 0.1 // having fixed 10% tax for testing
            let totalAmount = subtotalAmount + taxAmount
            formattedOrderTotalTaxPrice = currencyFormatter.formatAmount(Decimal(taxAmount))
            formattedOrderTotalPrice = currencyFormatter.formatAmount(Decimal(totalAmount))
        }
    }

    func cardPaymentTapped() {
        Task { @MainActor in
            showsCreatingOrderSheet = true

            // Once we have finalised order creation/update, this check shouldn't be required.
            // Instead, we should have whatever code does the order creation/update kick off this connection process.
            guard let order = try? await createOrUpdateTestOrder() else {
                showsCardReaderSheet = false
                return DDLogError("Error creating or updating order")
            }

            showsCreatingOrderSheet = false
            try await collectPayment(for: order)
        }
    }

    @MainActor
    private func collectPayment(for order: Order) async throws {
        let _ = try await cardPresentPaymentService.collectPayment(for: order, using: .bluetooth)

        // TODO: Here we should present something to show the payment was successful or not,
        // and then clear the screen ready for the next transaction.
    }

    @MainActor
    func totalsViewWillAppear() async {
        // Digging in to the connection viewmodel here is a bit of a shortcut, we should improve this.
        // TODO: Have our own subscription to the connected readers
        if cardReaderConnectionViewModel.connectionStatus == .connected {
            // Once we have finalised order creation/update, this check shouldn't be required.
            // Instead, we should have whatever code does the order creation/update kick off this connection process.
            guard let order = try? await createOrUpdateTestOrder() else {
                return DDLogError("Error creating or updating order")
            }

            do {
                // Since this function is called from a `task`, it'll be cancelled automatically if the view is removed.
                // Proper cancellation isn't implemented yet, so that can lead to some unwanted behaviour, but currently
                // if you go back during a payment, it will still complete.
                // TODO: We should consider disabling the `Add More` button when the shopper taps their card.
                try await collectPayment(for: order)
            } catch {
                DDLogError("Error taking payment: \(error)")
            }
        }
    }

    @MainActor
    func onTotalsViewDisappearance() {
        cardPresentPaymentService.cancelPayment()
    }
}

private extension PointOfSaleDashboardViewModel {
    func observeItemsInCartForCartTotal() {
        $itemsInCart
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
            case .showReaderList,
                    .showOnboarding:
                return true
            }
        }.assign(to: &$showsCardReaderSheet)
    }
}

import enum Yosemite.OrderAction
import struct Yosemite.Order
@MainActor
private extension PointOfSaleDashboardViewModel {
    private func createOrUpdateTestOrder() async throws -> Order {
        if let order {
            let updatedOrder = try await update(order: order, amount: formattedOrderTotalPrice ?? "15.00")
            self.order = updatedOrder
            return updatedOrder
        } else {
            let order = try await createTestOrder(amount: formattedOrderTotalPrice ?? "15.00")
            self.order = order
            return order
        }
    }

    func createTestOrder(amount: String = "15.00") async throws -> Order {
           return try await withCheckedThrowingContinuation { continuation in
               let action = OrderAction.createSimplePaymentsOrder(siteID: ServiceLocator.stores.sessionManager.defaultStoreID ?? 0,
                                                                  status: .pending,
                                                                  amount: amount,
                                                                  taxable: false) { result in
                   continuation.resume(with: result)
               }
               ServiceLocator.stores.dispatch(action)
           }
       }

    func update(order: Order, amount: String) async throws -> Order {
        return try await withCheckedThrowingContinuation { continuation in
            let action = OrderAction.updateSimplePaymentsOrder(siteID: ServiceLocator.stores.sessionManager.defaultStoreID ?? 0,
                                                               orderID: order.orderID,
                                                               feeID: order.fees.first?.feeID ?? 0,
                                                               status: .autoDraft,
                                                               amount: amount,
                                                               taxable: false,
                                                               orderNote: order.customerNote,
                                                               email: "") { result in
                continuation.resume(with: result)
            }
            ServiceLocator.stores.dispatch(action)
        }
    }
}
