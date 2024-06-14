import Combine
import SwiftUI
import class Yosemite.PointOfSaleOrderService
import protocol Yosemite.PointOfSaleOrderServiceProtocol
import struct Yosemite.PointOfSaleOrder
import struct Yosemite.PointOfSaleCartItem
import struct Yosemite.PointOfSaleCartProduct
import protocol Yosemite.POSItem
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import enum Networking.OrderStatusEnum

final class PointOfSaleDashboardViewModel: ObservableObject {
    enum PaymentState {
        case acceptingCard
        case processingCard
        case cardPaymentSuccessful
    }

    @Published private(set) var items: [POSItem]
    @Published private(set) var itemsInCart: [CartItem] = []
    @Published private var finalItems: [CartItem] = []

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

    @Published private var order: PointOfSaleOrder?
    @Published private(set) var isSyncingOrder: Bool = false
    private let orderService: PointOfSaleOrderServiceProtocol
    private var cartSubscription: AnyCancellable?

    private let cardPresentPaymentService: CardPresentPaymentFacade

    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

    init(items: [POSItem],
         cardPresentPaymentService: CardPresentPaymentFacade,
         // TODO: DI to entry point from the app
         orderService: PointOfSaleOrderServiceProtocol) {
        self.items = items
        self.cardPresentPaymentService = cardPresentPaymentService
        self.cardReaderConnectionViewModel = CardReaderConnectionViewModel(cardPresentPayment: cardPresentPaymentService)
        self.orderService = orderService

        observeCardPresentPaymentEvents()
        observeItemsInCartForCartTotal()
        observeProductsInCartForRemoteOrderSyncing()
    }

    var itemToScrollToWhenCartUpdated: CartItem? {
        return itemsInCart.last
    }

    func addItemToCart(_ item: POSItem) {
        let cartItem = CartItem(id: UUID(), item: item, quantity: 1)
        itemsInCart.append(cartItem)

        if orderStage == .finalizing {
            createOrUpdateOrder()
        }
    }

    func removeItemFromCart(_ cartItem: CartItem) {
        itemsInCart.removeAll(where: { $0.id == cartItem.id })

        if orderStage == .finalizing {
            createOrUpdateOrder()
        }
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

        createOrUpdateOrder()
    }

    func addMoreToCart() {
        orderStage = .building
    }

    func showFilters() {
        showsFilterSheet = true
    }

    var areAmountsFullyCalculated: Bool {
        return isSyncingOrder == false && formattedOrderTotalTaxPrice != nil && formattedOrderTotalPrice != nil
    }
    var showRecalculateButton: Bool {
        return !areAmountsFullyCalculated && isSyncingOrder == false
    }

    var checkoutButtonDisabled: Bool {
        return itemsInCart.isEmpty
    }

    func cardPaymentTapped() {
        Task { @MainActor in
            showsCreatingOrderSheet = true
            let finalOrder = orderService.orderFrom(posOrder: order)
            showsCreatingOrderSheet = false
            let result = try await cardPresentPaymentService.collectPayment(for: finalOrder, using: .bluetooth)

            // TODO: Here we should present something to show the payment was successful or not,
            // and then clear the screen ready for the next transaction.
            switch result {
            case .success(let cardPresentPaymentTransaction):
                print("🟢 [POS] Payment successful: \(cardPresentPaymentTransaction)")
            case .cancellation:
                print("🟡 [POS] Payment cancelled")
            }
        }
    }

    func updateOrderStatus(_ status: OrderStatusEnum) {
        guard let order else {
            return
        }
        Task { @MainActor
            [weak self] in
            guard let self else {
                throw OrderSyncError.selfDeallocated
            }
            do {
                let finalizedOrder = try await self.orderService.updateOrderStatus(posOrder: order, status: status)
                self.order = finalizedOrder
                print("🟢 [POS] Synced order: \(finalizedOrder)")
            } catch {
                print("🔴 [POS] Error syncing order: \(error)")
            }
        }
    }

    func calculateAmountsTapped() {
        createOrUpdateOrder()
    }

    private func createOrUpdateOrder() {
        finalItems = itemsInCart
    }

    func startNewTransaction() {
        // clear cart
        itemsInCart.removeAll()
        orderStage = .building
        order = nil
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
            case .showAlert,
                    .showReaderList,
                    .showOnboarding:
                return true
            }
        }.assign(to: &$showsCardReaderSheet)
    }

    func observeProductsInCartForRemoteOrderSyncing() {
        cartSubscription = Publishers.CombineLatest($finalItems.debounce(for: .seconds(Constants.cartChangesDebounceDuration),
                                                                          scheduler: DispatchQueue.main),
                                                    $isSyncingOrder)
        .filter { _, isSyncingOrder in
            isSyncingOrder == false
        }
        .map { $0.0 }
        .removeDuplicates()
        .dropFirst()
        .sink { cartProducts in
            Task { @MainActor
                [weak self] in
                guard let self else {
                    throw OrderSyncError.selfDeallocated
                }
                let cart = cartProducts
                    .map {
                        PointOfSaleCartItem(itemID: nil,
                                            product: .init(productID: $0.item.productID,
                                                           price: $0.item.price,
                                                           productType: .simple),
                                            quantity: Decimal($0.quantity))
                    }
                defer {
                    self.isSyncingOrder = false
                }
                do {
                    self.isSyncingOrder = true
                    let posProducts = self.items.map { Yosemite.PointOfSaleCartProduct(productID: $0.productID,
                                                                                             price: $0.price,
                                                                                             productType: .simple) }
                    let order = try await self.orderService.syncOrder(cart: cart,
                                                                            order: self.order,
                                                                            allProducts: posProducts)
                    self.order = order
                    print("🟢 [POS] Synced order: \(order)")
                } catch {
                    print("🔴 [POS] Error syncing order: \(error)")
                }
            }
        }
    }
}

private extension PointOfSaleDashboardViewModel {
    enum Constants {
        static let cartChangesDebounceDuration: TimeInterval = 0
    }

    enum OrderSyncError: Error {
        case selfDeallocated
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
