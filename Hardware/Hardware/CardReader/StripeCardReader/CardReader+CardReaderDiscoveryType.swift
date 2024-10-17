import Foundation

public extension CardReader {
    var discoveryMethod: CardReaderDiscoveryMethod? {
        switch readerType {
        case .appleBuiltIn:
            return .localMobile
        case .chipper, .stripeM2, .wisepad3:
            return .bluetoothScan
        case .remoteTapToPay:
            return .remoteMobile
        case .other:
            return nil
        }
    }
}
