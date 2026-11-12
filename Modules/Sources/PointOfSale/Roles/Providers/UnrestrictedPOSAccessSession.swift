@MainActor
final class UnrestrictedPOSAccessSession: POSAccessSession {
    nonisolated init() {}

    var currentStaff: POSStaff? { nil }
    var isLocked: Bool { false }
    var isPINProtectionEnabled: Bool { false }

    func refreshPINProtection() throws(POSPINStoreError) {}

    func allows(_ capability: POSCapability) -> Bool { true }
    func signIn(withPIN pin: String) async throws(POSAuthError) {}
    func requestManagerApproval(withPIN pin: String, for capability: POSCapability) async throws(POSAuthError) {}
    func lock() {}
    func checkLockoutState() throws(POSAuthError) {}
}
