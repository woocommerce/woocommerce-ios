import Foundation

enum CardPresentPaymentReaderConnectionStatus: Equatable {
    case disconnected
    case connected(CardPresentPaymentCardReader)
    case cancellingConnection
    case disconnecting
}
