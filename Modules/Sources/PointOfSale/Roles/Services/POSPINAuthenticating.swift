import Foundation

/// Protocol for authenticating PINs against the permission provider.
/// Returns true on success, false on wrong PIN.
/// Throws `POSAuthError.rateLimited` when too many attempts.
protocol POSPINAuthenticating {
    func authenticate(pin: String) async throws -> Bool
}

/// Authenticates PINs using the local on-device PIN service.
final class LocalPOSPINAuthenticator: POSPINAuthenticating {
    private let provider: LocalPOSPermissionProvider

    init(provider: LocalPOSPermissionProvider) {
        self.provider = provider
    }

    func authenticate(pin: String) async throws -> Bool {
        try provider.authenticatePIN(pin) != nil
    }
}

/// Authenticates PINs using the remote backend REST API.
final class RemotePOSPINAuthenticator: POSPINAuthenticating {
    private let provider: RemotePOSPermissionProvider

    init(provider: RemotePOSPermissionProvider) {
        self.provider = provider
    }

    func authenticate(pin: String) async throws -> Bool {
        _ = try await provider.authenticateRemotePIN(pin, registerID: "default")
        return true
    }
}
