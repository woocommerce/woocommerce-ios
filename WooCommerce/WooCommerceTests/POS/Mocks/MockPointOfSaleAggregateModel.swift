import Foundation
@testable import WooCommerce
import enum Yosemite.POSItem
import protocol Yosemite.POSOrderableItem

final class MockPointOfSaleAggregateModel: PointOfSaleAggregateModelProtocol {
    var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus

    func connectCardReader() { }

    func disconnectCardReader() { }

    var paymentState: WooCommerce.PointOfSalePaymentState

    var cardPresentPaymentAlertViewModel: WooCommerce.PointOfSaleCardPresentPaymentAlertType?

    var cardPresentPaymentInlineMessage: WooCommerce.PointOfSaleCardPresentPaymentMessageType?

    var cardPresentPaymentOnboardingViewModel: WooCommerce.CardPresentPaymentsOnboardingViewModel?

    func cancelCardPaymentsOnboarding() { }

    func trackCardPaymentsOnboardingShown() { }

    var orderStage: PointOfSaleOrderStage

    var orderState: WooCommerce.PointOfSaleOrderState

    var itemsViewState: ItemsViewState
    var blockReturnToItemSelection: Bool = false

    init(cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected,
         itemsViewState: ItemsViewState = ItemsViewState(containerState: .loading, itemsStack: ItemsStackState(root: .loading([]),
                                                                                                               itemStates: [:])),
         orderStage: PointOfSaleOrderStage = .building,
         orderState: PointOfSaleOrderState = .idle,
         paymentState: PointOfSalePaymentState = .card(.idle)) {
        self.cardReaderConnectionStatus = cardReaderConnectionStatus
        self.itemsViewState = itemsViewState
        self.orderStage = orderStage
        self.orderState = orderState
        self.paymentState = paymentState
    }

    func loadItems(base: ItemListBaseItem) async { }

    func loadNextItems(base: ItemListBaseItem) async { }

    var cart: [CartItem] = []

    func addToCart(_ item: POSItem) { }

    func remove(cartItem: CartItem) { }

    var removeAllItemsFromCartCalled = false
    func removeAllItemsFromCart() {
        removeAllItemsFromCartCalled = true
    }

    func checkOut() async { }

    func addMoreToCart() { }

    func startNewCart() { }
}
