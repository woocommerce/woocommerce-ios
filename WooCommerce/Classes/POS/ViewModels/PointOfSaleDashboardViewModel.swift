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
    @Published private(set) var cardPresentPaymentAlertViewModel: CardPresentPaymentAlertType?
    @Published private(set) var cardPresentPaymentInlineMessage: CardPresentPaymentMessageType?
    let cardReaderConnectionViewModel: CardReaderConnectionViewModel

    @Published var showsCreatingOrderSheet: Bool = false

    @Published var showsFilterSheet: Bool = false

    enum OrderStage {
        case building
        case finalizing
    }

    @Published private(set) var orderStage: OrderStage = .building

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

    func showFilters() {
        showsFilterSheet = true
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

    var checkoutButtonDisabled: Bool {
        return itemsInCart.isEmpty
    }

    func cardPaymentTapped() {
        Task { @MainActor in
            showsCreatingOrderSheet = true
            let order = try await createTestOrder()
            showsCreatingOrderSheet = false
            let _ = try await cardPresentPaymentService.collectPayment(for: order, using: .bluetooth)

            // TODO: Here we should present something to show the payment was successful or not,
            // and then clear the screen ready for the next transaction.
        }
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
            .map { event in
                guard case let .showAlert(alertDetails) = event else {
                    return nil
                }
                return alertDetails
            }
            .assign(to: &$cardPresentPaymentAlertViewModel)
        cardPresentPaymentService.paymentEventPublisher
            .map { event in
                guard case let .showPaymentMessage(messageType) = event else {
                    return nil
                }
                return messageType
            }
            .assign(to: &$cardPresentPaymentInlineMessage)
        cardPresentPaymentService.paymentEventPublisher.map { event in
            switch event {
            case .idle, .showPaymentMessage:
                return false
            case .showAlert:
                return true
            case .showReaderList,
                    .showOnboarding:
                // TODO: support these cases separately from `showAlert`
                return false
            }
        }.assign(to: &$showsCardReaderSheet)
    }
}

import enum Yosemite.OrderAction
import struct Yosemite.Order
private extension PointOfSaleDashboardViewModel {
    @MainActor
       func createTestOrder() async throws -> Order {
           return try await withCheckedThrowingContinuation { continuation in
               let action = OrderAction.createSimplePaymentsOrder(siteID: ServiceLocator.stores.sessionManager.defaultStoreID ?? 0,
                                                                  status: .pending,
                                                                  amount: "15.00",
                                                                  taxable: false) { result in
                   continuation.resume(with: result)
               }
               ServiceLocator.stores.dispatch(action)
           }
       }
}
