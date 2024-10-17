#if !targetEnvironment(macCatalyst)
import StripeTerminal

public extension CardReaderDiscoveryMethod {
    func toStripe() -> DiscoveryMethod {
        switch self {
        case .localMobile, .remoteMobile:
            return .localMobile
        case .bluetoothScan:
            return .bluetoothScan
        }
    }
}
#endif
