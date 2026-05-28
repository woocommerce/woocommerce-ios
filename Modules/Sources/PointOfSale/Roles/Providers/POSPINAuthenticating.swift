protocol POSPINAuthenticating: Sendable {
    func authenticate(withPIN pin: String) async throws(POSAuthError) -> POSStaff
    func verify(managerPIN pin: String, authorizes capability: POSCapability) async throws(POSAuthError) -> POSStaff
}
