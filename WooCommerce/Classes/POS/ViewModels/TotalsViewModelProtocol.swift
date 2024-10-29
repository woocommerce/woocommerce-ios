import Combine
import struct Yosemite.Order
import protocol Yosemite.POSItem

protocol TotalsViewModelProtocol {
    var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType? { get }
    var order: Order? { get }

    func startNewOrder()
}
