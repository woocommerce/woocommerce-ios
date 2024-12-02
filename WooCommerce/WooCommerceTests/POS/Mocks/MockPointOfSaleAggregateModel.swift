import Foundation
@testable import WooCommerce
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

    var itemListState: ItemListState
    var blockReturnToItemSelection: Bool = false

    init(cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected,
         itemListState: ItemListState = .initialLoading,
         orderStage: PointOfSaleOrderStage = .building,
         orderState: PointOfSaleOrderState = .idle,
         paymentState: PointOfSalePaymentState = .idle) {
        self.cardReaderConnectionStatus = cardReaderConnectionStatus
        self.itemListState = itemListState
        self.orderStage = orderStage
        self.orderState = orderState
        self.paymentState = paymentState
    }

    func loadInitialItems() async { }

    func loadNextItems() async { }

    func reload() async { }

    var cart: [CartItem] = []

    func addToCart(_ item: any POSOrderableItem) { }

    func remove(cartItem: CartItem) { }

    var removeAllItemsFromCartCalled = false
    func removeAllItemsFromCart() {
        removeAllItemsFromCartCalled = true
    }

    func checkOut() async { }

    func addMoreToCart() { }

    func startNewCart() { }
}
