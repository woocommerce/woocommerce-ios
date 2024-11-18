import Foundation
@testable import WooCommerce
import protocol Yosemite.POSItem

final class MockPointOfSaleAggregateModel: PointOfSaleAggregateModelProtocol {
    var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus

    func connectCardReader() { }

    func disconnectCardReader() { }

    var paymentState: WooCommerce.PointOfSalePaymentState

    var cardPresentPaymentAlertViewModel: WooCommerce.PointOfSaleCardPresentPaymentAlertType?

    var cardPresentPaymentInlineMessage: WooCommerce.PointOfSaleCardPresentPaymentMessageType?

    var orderStage: PointOfSaleOrderStage

    var orderState: WooCommerce.PointOfSaleOrderState

    var allItems: [POSItem] {
        switch itemListState {
        case .empty,
                .initialLoading,
                .error:
            return []
        case .loading(let items),
            .loaded(let items):
            return items
        }
    }

    var itemListState: ItemListState

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

    func addToCart(_ item: any Yosemite.POSItem) { }

    func remove(cartItem: WooCommerce.CartItem) { }

    var removeAllItemsFromCartCalled = false
    func removeAllItemsFromCart() {
        removeAllItemsFromCartCalled = true
    }

    func submitCart() { }

    func checkOut() async { }

    func addMoreToCart() { }

    func startNewCart() { }
}
