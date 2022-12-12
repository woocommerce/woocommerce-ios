#if !targetEnvironment(macCatalyst)
import Foundation
import StripeTerminal

public enum CardReaderDiscoveryMethod {
    case localMobile
    case bluetoothScan

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
