import Foundation

enum CardPresentPaymentReaderConnectionStatus: Equatable {
    case disconnected
    case connected(CardPresentPaymentCardReader)
    case disconnecting
}
