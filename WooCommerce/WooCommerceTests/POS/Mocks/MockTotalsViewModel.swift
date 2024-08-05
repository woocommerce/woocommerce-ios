import Combine
import Foundation
@testable import WooCommerce
import protocol Yosemite.POSItem
import struct Yosemite.Order

final class MockTotalsViewModel: TotalsViewModelProtocol {
    var order: Yosemite.Order?

    @Published var isSyncingOrder: Bool = false
    @Published var paymentState: TotalsViewModel.PaymentState = .idle
    @Published var showsCardReaderSheet: Bool = false
    @Published var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    @Published var cardPresentPaymentEvent: CardPresentPaymentEvent = .idle
    @Published var connectionStatus: CardReaderConnectionStatus = .disconnected
    @Published var formattedCartTotalPrice: String?
    @Published var formattedOrderTotalPrice: String?
    @Published var formattedOrderTotalTaxPrice: String?

    var isSyncingOrderPublisher: Published<Bool>.Publisher { $isSyncingOrder }
    var paymentStatePublisher: Published<TotalsViewModel.PaymentState>.Publisher { $paymentState }
    var showsCardReaderSheetPublisher: Published<Bool>.Publisher { $showsCardReaderSheet }
    var cardPresentPaymentAlertViewModelPublisher: Published<PointOfSaleCardPresentPaymentAlertType?>.Publisher { $cardPresentPaymentAlertViewModel }
    var cardPresentPaymentEventPublisher: Published<CardPresentPaymentEvent>.Publisher { $cardPresentPaymentEvent }
    var connectionStatusPublisher: Published<CardReaderConnectionStatus>.Publisher { $connectionStatus }
    var formattedCartTotalPricePublisher: Published<String?>.Publisher { $formattedCartTotalPrice }
    var formattedOrderTotalPricePublisher: Published<String?>.Publisher { $formattedOrderTotalPrice }
    var formattedOrderTotalTaxPricePublisher: Published<String?>.Publisher { $formattedOrderTotalTaxPrice }

    var isShimmering: Bool {
        isSyncingOrder
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

    var showRecalculateButton: Bool {
        !areAmountsFullyCalculated && isSyncingOrder == false
    }

    var areAmountsFullyCalculated: Bool {
        formattedOrderTotalTaxPrice != nil && formattedOrderTotalPrice != nil && isSyncingOrder == false
    }

    func startSyncingOrder(with cartItems: [CartItem], allItems: [POSItem]) {
        isSyncingOrder = true
    }

    func startNewTransaction() {
        paymentState = .acceptingCard
    }

    func calculateAmountsTapped(with cartItems: [CartItem], allItems: [POSItem]) {
        // Provide a mock implementation if needed
    }

    func cardPaymentTapped() {
        // Provide a mock implementation if needed
    }

    func onTotalsViewDisappearance() {
        // Provide a mock implementation if needed
    }
}
