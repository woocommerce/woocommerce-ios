protocol POSPINAuthenticating: Sendable {
    /// An unknown error must mean the credential source failed before any PIN comparison.
    func authenticate(withPIN pin: String) async throws(POSAuthError) -> POSStaff
    func verify(managerPIN pin: String, authorizes capability: POSCapability) async throws(POSAuthError)
}
