#if !targetEnvironment(macCatalyst)
import Foundation
import StripeTerminal

public enum CardReaderDiscoveryMethod {
    case localMobile
    case bluetoothProximity

    func toStripe() -> DiscoveryMethod {
        switch self {
        case .localMobile:
            return .localMobile
        case .bluetoothProximity:
            return .bluetoothProximity
        }
    }
}
#endif
