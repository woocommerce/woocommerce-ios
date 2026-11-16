@MainActor
final class UnrestrictedPOSAccessSession: POSAccessSession {
    nonisolated init() {}

    var currentStaff: POSStaff? { nil }
    var isLocked: Bool { false }
    var isPINProtectionEnabled: Bool { false }

    func refreshPINProtection() throws(POSPINStoreError) {}
    func beginPINChange() throws(POSPINStoreError) -> POSPINChangeRegistration { POSPINChangeRegistration {} }

    func allows(_ capability: POSCapability) -> Bool { true }
    func signIn(withPIN pin: String) async throws(POSAuthError) {}
    func requestManagerApproval(withPIN pin: String, for requiredCapability: POSCapability) async throws(POSAuthError) {}
    func lock() {}
    func endSession() {}
    func saveElapsedTime() async {}

    func checkLockoutState() async throws(POSAuthError) {}
}
