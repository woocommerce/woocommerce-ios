import Foundation

public enum CardPresentPaymentReaderConnectionResult {
    case connected(CardPresentPaymentCardReader)
    case canceled
}

// This should be internal if/when we move the CardPresentPaymentService to Yosemite or another framework
import enum Yosemite.CardReaderDiscoveryMethod
extension CardReaderConnectionMethod {
    public var discoveryMethod: CardReaderDiscoveryMethod {
        switch self {
        case .bluetooth:
            return .bluetoothScan
        case .tapToPay:
            return .tapToPay
        }
    }
}
