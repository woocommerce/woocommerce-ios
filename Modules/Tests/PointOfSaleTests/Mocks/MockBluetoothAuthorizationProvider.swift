import enum WooFoundation.BluetoothAuthorization
import protocol WooFoundation.BluetoothAuthorizationProviding

/// Test double for `BluetoothAuthorizationProviding` that returns a stubbed authorization, mutable
/// between reads so tests can simulate the merchant toggling the permission.
final class MockBluetoothAuthorizationProvider: BluetoothAuthorizationProviding {
    var stubbedAuthorization: BluetoothAuthorization

    init(authorization: BluetoothAuthorization = .allowed) {
        self.stubbedAuthorization = authorization
    }

    var current: BluetoothAuthorization {
        stubbedAuthorization
    }
}
