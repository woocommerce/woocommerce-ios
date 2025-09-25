import Foundation
@testable import PointOfSale
import enum Yosemite.POSItem
import protocol Yosemite.POSOrderableItem
import enum Yosemite.POSItemType

final class MockPointOfSaleAggregateModel: PointOfSaleAggregateModelProtocol {
    var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus

    func connectCardReader() { }

    func disconnectCardReader() { }

    var paymentState: PointOfSale.PointOfSalePaymentState

    var cardPresentPaymentAlertViewModel: PointOfSale.PointOfSaleCardPresentPaymentAlertType?

    var cardPresentPaymentInlineMessage: PointOfSale.PointOfSaleCardPresentPaymentMessageType?

    var cardPresentPaymentOnboardingViewContainer: PointOfSale.CardPresentPaymentOnboardingViewContainer?

    func cancelCardPaymentsOnboarding() { }

    func trackCardPaymentsOnboardingShown() { }

    var orderStage: PointOfSaleOrderStage

    var orderState: PointOfSale.PointOfSaleOrderState

    var purchasableItemsController: any PointOfSale.PointOfSaleItemsControllerProtocol

    var purchasableItemsSearchController: any PointOfSale.PointOfSaleSearchingItemsControllerProtocol

    var couponsController: any PointOfSale.PointOfSaleCouponsControllerProtocol

    var couponsSearchController: any PointOfSale.PointOfSaleSearchingItemsControllerProtocol

    var blockReturnToItemSelection: Bool = false

    init(cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected,
         purchasableItemsController: PointOfSaleItemsControllerProtocol = MockPointOfSaleItemsController(),
         purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol = MockPointOfSalePurchasableItemsSearchController(),
         couponsController: PointOfSaleCouponsControllerProtocol = MockPointOfSaleCouponsController(),
         couponsSearchController: PointOfSaleSearchingItemsControllerProtocol = MockPointOfSaleCouponsController(),
         orderStage: PointOfSaleOrderStage = .building,
         orderState: PointOfSaleOrderState = .idle,
         paymentState: PointOfSalePaymentState = .idle) {
        self.cardReaderConnectionStatus = cardReaderConnectionStatus
        self.purchasableItemsController = purchasableItemsController
        self.purchasableItemsSearchController = purchasableItemsSearchController
        self.couponsController = couponsController
        self.couponsSearchController = couponsSearchController
        self.orderStage = orderStage
        self.orderState = orderState
        self.paymentState = paymentState
    }

    func loadItems(base: ItemListBaseItem) async { }

    func loadNextItems(base: ItemListBaseItem) async { }

    var cart: Cart = .init()

    func barcodeScanned(_ result: Result<String, HIDBarcodeParserError>) { }

    func addToCart(_ item: POSItem) { }

    func remove(cartItem: CartItem) { }

    var removeAllItemsFromCartCalled = false
    func removeAllItemsFromCart() {
        removeAllItemsFromCartCalled = true
    }

    func removeAllItemsFromCart(types: [CartItemType]) { }

    func checkOut() async { }

    func addMoreToCart() { }

    func startNewCart() { }

    func pointOfSaleClosed() { }

    func saveSearchTerm(_ term: String, for itemType: POSItemType) { }

    func searchHistory(for itemType: Yosemite.POSItemType) -> [String] {
        return []
    }

    func loadPopularItems(type: Yosemite.POSItemType) async { }
}
