import Foundation
@testable import WooCommerce
import enum Yosemite.POSItem
import protocol Yosemite.POSOrderableItem
import enum Yosemite.POSItemType

@available(iOS 17.0, *)
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

    var purchasableItemsController: any WooCommerce.PointOfSaleItemsControllerProtocol

    var purchasableItemsSearchController: any WooCommerce.PointOfSaleSearchingItemsControllerProtocol

    var couponsController: any WooCommerce.PointOfSaleCouponsControllerProtocol

    var blockReturnToItemSelection: Bool = false

    init(cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected,
         purchasableItemsController: PointOfSaleItemsControllerProtocol = MockPointOfSaleItemsController(),
         purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol = MockPointOfSalePurchasableItemsSearchController(),
         couponsController: PointOfSaleCouponsControllerProtocol = MockPointOfSaleCouponsController(),
         orderStage: PointOfSaleOrderStage = .building,
         orderState: PointOfSaleOrderState = .idle,
         paymentState: PointOfSalePaymentState = .card(.idle)) {
        self.cardReaderConnectionStatus = cardReaderConnectionStatus
        self.purchasableItemsController = purchasableItemsController
        self.purchasableItemsSearchController = purchasableItemsSearchController
        self.couponsController = couponsController
        self.orderStage = orderStage
        self.orderState = orderState
        self.paymentState = paymentState
    }

    func loadItems(base: ItemListBaseItem) async { }

    func loadNextItems(base: ItemListBaseItem) async { }

    var cart: Cart = .init()

    func addToCart(_ item: POSItem) { }

    func remove(cartItem: CartItem) { }

    func remove(cartCouponItem: CartCouponItem) { }

    var removeAllItemsFromCartCalled = false
    func removeAllItemsFromCart() {
        removeAllItemsFromCartCalled = true
    }

    func removeAllCouponsFromCart() { }

    func checkOut() async { }

    func addMoreToCart() { }

    func startNewCart() { }

    func pointOfSaleClosed() { }

    func saveSearchTerm(_ term: String, for itemType: POSItemType) { }

    func searchHistory(for itemType: Yosemite.POSItemType) -> [String] {
        return []
    }
}
