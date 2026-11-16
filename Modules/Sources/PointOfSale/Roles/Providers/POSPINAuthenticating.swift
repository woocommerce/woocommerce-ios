protocol POSPINAuthenticating: Sendable {
    func authenticate(withPIN pin: String) async throws(POSAuthError) -> POSStaff
}
