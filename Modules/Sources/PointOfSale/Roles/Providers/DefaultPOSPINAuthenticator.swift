import Foundation

struct DefaultPOSPINAuthenticator: POSPINAuthenticating {
    // TODO: Replace with PBKDF2 verification against a cached staff list once the staff endpoint lands.

    func authenticate(withPIN pin: String) async throws(POSAuthError) -> POSStaff {
        guard pin == "1234" else {
            throw .invalidPIN
        }
        return POSStaff(
            displayName: "Demo Manager",
            role: "shop_manager",
            capabilities: Set(POSCapability.allCases.map(\.rawValue))
        )
    }

    func verify(managerPIN pin: String, authorizes capability: POSCapability)
        async throws(POSAuthError) {
        throw .unknown
    }

    func hasAnyPINs() async throws(POSAuthError) -> Bool {
        true
    }
}
