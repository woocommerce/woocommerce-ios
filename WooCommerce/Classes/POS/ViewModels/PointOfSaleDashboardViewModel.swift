import SwiftUI
import protocol Yosemite.POSItem
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

final class PointOfSaleDashboardViewModel: ObservableObject {
    enum PaymentState {
        case acceptingCard
        case processingCard
        case cardPaymentSuccessful
        case acceptingCash
        case cashPaymentSuccessful
    }

    @Published private(set) var items: [POSItem]
    @Published private(set) var itemsInCart: [CartItem] = []

    // Subtotal, Taxes...
    @Published private(set) var formattedCartTotalPrice: String?
    @Published private(set) var formattedOrderTotalTaxPrice: String?
    // Total
    @Published private(set) var formattedOrderTotalPrice: String?

    @Published var showsCardReaderSheet: Bool = false
    @Published private(set) var cardPresentPaymentEvent: CardPresentPaymentEvent = .idle
    @ObservedObject private(set) var cardReaderConnectionViewModel: CardReaderConnectionViewModel

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

    func addItemToCart(_ item: POSItem) {
        let cartItem = CartItem(id: UUID(), item: item, quantity: 1)
        itemsInCart.append(cartItem)
        resetCalculatedAmounts()
    }

    func removeItemFromCart(_ cartItem: CartItem) {
        itemsInCart.removeAll(where: { $0.id == cartItem.id })
        resetCalculatedAmounts()
        checkIfCartEmpty()
    }

    private func checkIfCartEmpty() {
        if itemsInCart.isEmpty {
            orderStage = .building
        }
    }

    func submitCart() {
        // TODO: https://github.com/woocommerce/woocommerce-ios/issues/12810
        orderStage = .finalizing
        calculateAmounts()
    }

    func addMoreToCart() {
        orderStage = .building
    }

    func showFilters() {
        showsFilterSheet = true
    }

    private func resetCalculatedAmounts() {
        formattedOrderTotalTaxPrice = nil
        formattedOrderTotalPrice = nil
    }

    var areAmountsFullyCalculated: Bool {
        return calculatingAmounts == false && (formattedOrderTotalTaxPrice != nil || formattedOrderTotalPrice != nil)
    }
    var showRecalculateButton: Bool {
        return !areAmountsFullyCalculated && calculatingAmounts == false
    }

    @Published private(set) var calculatingAmounts: Bool = false

    func recalculateAmounts() {
        resetCalculatedAmounts()
        calculateAmounts()
    }

    private func calculateAmounts() {
        // TODO: this is just a starting point for this logic, to have something calculated on the fly
        if let formattedCartTotalPrice = formattedCartTotalPrice,
           let subtotalAmount = currencyFormatter.convertToDecimal(formattedCartTotalPrice)?.doubleValue {
            let taxAmount = subtotalAmount * 0.1 // having fixed 10% tax for testing
            let totalAmount = subtotalAmount + taxAmount
            calculatingAmounts = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.formattedOrderTotalTaxPrice = self.currencyFormatter.formatAmount(Decimal(taxAmount))
                self.formattedOrderTotalPrice = self.currencyFormatter.formatAmount(Decimal(totalAmount))
                self.calculatingAmounts = false
            })
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

    func startNewTransaction() {
        // clear cart
        itemsInCart.removeAll()
        orderStage = .building
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
        cardPresentPaymentService.paymentEventPublisher.map { event in
            switch event {
            case .idle:
                return false
            case .showAlert,
                    .showReaderList,
                    .showOnboarding:
                return true
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
