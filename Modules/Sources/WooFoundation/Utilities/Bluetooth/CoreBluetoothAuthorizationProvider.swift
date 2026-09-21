import CoreBluetooth

/// `BluetoothAuthorizationProviding` backed by CoreBluetooth.
///
/// Keeps the CoreBluetooth import contained in WooFoundation so callers (such as POS) can read the
/// permission without linking the framework themselves. Reading `CBManager.authorization` is a
/// static check that neither instantiates a manager nor prompts the merchant.
public struct CoreBluetoothAuthorizationProvider: BluetoothAuthorizationProviding {
    public init() {}

    public var current: BluetoothAuthorization {
        switch CBManager.authorization {
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .allowedAlways:
            return .allowed
        @unknown default:
            return .allowed
        }
    }
}
