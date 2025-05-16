#if !targetEnvironment(macCatalyst)
import StripeTerminal

public extension CardReaderDiscoveryMethod {
    func toStripe() -> DiscoveryMethod {
        switch self {
        case .tapToPay:
            return .tapToPay
        case .bluetoothScan:
            return .bluetoothScan
        }
    }
}
#endif
