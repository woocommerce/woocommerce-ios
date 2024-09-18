import Combine
import Foundation
@testable import WooCommerce
import protocol Yosemite.POSItem
import struct Yosemite.Order

final class MockTotalsViewModel: TotalsViewModelProtocol {

    var order: Yosemite.Order?

    @Published var orderState: TotalsViewModel.OrderState = .loaded
    @Published var paymentState: TotalsViewModel.PaymentState = .idle
    @Published var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    @Published var cardPresentPaymentEvent: CardPresentPaymentEvent = .idle
    @Published var connectionStatus: CardReaderConnectionStatus = .disconnected
    @Published var formattedCartTotalPrice: String?
    @Published var formattedOrderTotalPrice: String?
    @Published var formattedOrderTotalTaxPrice: String?
    @Published var startNewOrderAction: Void = ()
    @Published var editOrderAction: Void = ()

    var orderStatePublisher: Published<TotalsViewModel.OrderState>.Publisher { $orderState }
    var paymentStatePublisher: Published<TotalsViewModel.PaymentState>.Publisher { $paymentState }
    var cardPresentPaymentAlertViewModelPublisher: Published<PointOfSaleCardPresentPaymentAlertType?>.Publisher { $cardPresentPaymentAlertViewModel }
    var cardPresentPaymentEventPublisher: Published<CardPresentPaymentEvent>.Publisher { $cardPresentPaymentEvent }
    var connectionStatusPublisher: Published<CardReaderConnectionStatus>.Publisher { $connectionStatus }
    var formattedCartTotalPricePublisher: Published<String?>.Publisher { $formattedCartTotalPrice }
    var formattedOrderTotalPricePublisher: Published<String?>.Publisher { $formattedOrderTotalPrice }
    var formattedOrderTotalTaxPricePublisher: Published<String?>.Publisher { $formattedOrderTotalTaxPrice }
    var startNewOrderActionPublisher: AnyPublisher<Void, Never> { $startNewOrderAction.eraseToAnyPublisher() }
    var editOrderActionPublisher: AnyPublisher<Void, Never> { $editOrderAction.eraseToAnyPublisher() }

    var isShimmering: Bool {
        orderState.isSyncing
    }

    var isSyncingOrder: Bool {
        return orderState.isSyncing
    }

    var isSubtotalFieldRedacted: Bool {
        formattedCartTotalPrice == nil || isSyncingOrder
    }

    var isTaxFieldRedacted: Bool {
        formattedOrderTotalTaxPrice == nil || isSyncingOrder
    }

    var isTotalPriceFieldRedacted: Bool {
        formattedOrderTotalPrice == nil || isSyncingOrder
    }

    var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType? {
        // Provide a mock implementation if needed
        nil
    }

    func startNewOrder() {
        paymentState = .acceptingCard
    }

    func checkOutTapped(with cartItems: [CartItem], allItems: [POSItem]) {
        orderState = .syncing
    }

    func connectReaderTapped() {
        // Provide a mock implementation if needed
    }

    func onTotalsViewDisappearance() {
        // Provide a mock implementation if needed
    }

    var spyStopShowingTotalsViewCalled = false
    func stopShowingTotalsView() {
        spyStopShowingTotalsViewCalled = true
    }

    var spyStartShowingTotalsViewCalled = false
    func startShowingTotalsView() {
        spyStartShowingTotalsViewCalled = true
    }
}
