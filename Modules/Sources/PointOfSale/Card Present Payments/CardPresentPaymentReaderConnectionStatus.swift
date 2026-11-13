import Foundation

public enum CardPresentPaymentReaderConnectionStatus: Equatable, Sendable {
    case disconnected
    case connected(CardPresentPaymentCardReader)
    case cancellingConnection
    case disconnecting
    case reconnecting(CardPresentPaymentCardReader)
}

extension CardPresentPaymentReaderConnectionStatus {
    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
}
