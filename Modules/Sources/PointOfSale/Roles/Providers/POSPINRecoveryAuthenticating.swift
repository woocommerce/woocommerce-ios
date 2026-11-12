/// WOOMOB-4597 supplies fresh account authentication for this store. A stored app session is not proof.
protocol POSPINRecoveryAuthenticating: Sendable {
    func authenticate() async throws(POSAuthError) -> POSStaff
}

struct UnavailablePOSPINRecovery: POSPINRecoveryAuthenticating {
    func authenticate() async throws(POSAuthError) -> POSStaff { throw .unknown }
}
