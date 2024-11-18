import Combine
import struct Yosemite.Order
import protocol Yosemite.POSItem

protocol TotalsViewModelProtocol {
    var connectionStatus: CardPresentPaymentReaderConnectionStatus { get }

    func startNewOrder()

    func startShowingTotalsView()
    func stopShowingTotalsView()
}
