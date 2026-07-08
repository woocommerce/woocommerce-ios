/// The app's Bluetooth permission, as a system capability independent of any peripheral.
///
/// Mirrors the small surface of `ConnectivityObserver`: a generic device-capability read that
/// features can consult without importing CoreBluetooth.
public enum BluetoothAuthorization: Equatable {
    /// The merchant hasn't been asked for Bluetooth permission yet.
    case notDetermined
    /// Bluetooth permission is off (denied or restricted), so peripherals are unreachable.
    case denied
    /// Bluetooth permission is granted.
    case allowed
}

/// Reads the app's current Bluetooth permission.
public protocol BluetoothAuthorizationProviding {
    /// The current Bluetooth permission, read on demand.
    var current: BluetoothAuthorization { get }
}
