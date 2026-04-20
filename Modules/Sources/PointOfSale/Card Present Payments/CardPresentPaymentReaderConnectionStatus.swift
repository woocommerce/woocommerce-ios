import Foundation

public enum CardPresentPaymentReaderConnectionStatus: Equatable {
    case disconnected
    case connected(CardPresentPaymentCardReader)
    case cancellingConnection
    case disconnecting
    case reconnecting(CardPresentPaymentCardReader)
}
