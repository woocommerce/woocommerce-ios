#if !targetEnvironment(macCatalyst)
import StripeTerminal

public extension CardReaderDiscoveryMethod {
    func toStripe() -> DiscoveryMethod {
        switch self {
        case .localMobile:
            return .localMobile
        case .bluetoothScan:
            return .bluetoothScan
        }
    }
}
#endif
