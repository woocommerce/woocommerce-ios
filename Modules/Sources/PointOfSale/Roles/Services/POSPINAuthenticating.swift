import Foundation

/// Protocol for authenticating PINs against the permission provider.
protocol POSPINAuthenticating {
    func authenticate(pin: String) async -> Bool
    func verifyManagerPIN(_ pin: String) -> Bool
}

/// Authenticates PINs using the local on-device PIN service.
final class LocalPOSPINAuthenticator: POSPINAuthenticating {
    private let provider: LocalPOSPermissionProvider

    init(provider: LocalPOSPermissionProvider) {
        self.provider = provider
    }

    func authenticate(pin: String) async -> Bool {
        provider.authenticatePIN(pin) != nil
    }

    func verifyManagerPIN(_ pin: String) -> Bool {
        provider.verifyManagerPIN(pin)
    }
}

/// Authenticates PINs using the remote backend REST API.
final class RemotePOSPINAuthenticator: POSPINAuthenticating {
    private let provider: RemotePOSPermissionProvider

    init(provider: RemotePOSPermissionProvider) {
        self.provider = provider
    }

    func authenticate(pin: String) async -> Bool {
        do {
            _ = try await provider.authenticateRemotePIN(pin, registerID: "default")
            return true
        } catch {
            return false
        }
    }

    func verifyManagerPIN(_ pin: String) -> Bool {
        false
    }
}
