@MainActor
final class UnrestrictedPOSAccessSession: POSAccessSession {
    nonisolated init() {}

    var currentStaff: POSStaff? { nil }
    var isLocked: Bool { false }
    var pinStatus: POSPINStatus { .absent }

    func allows(_ capability: POSCapability) -> Bool { true }
    func signIn(withPIN pin: String) async throws(POSAuthError) {}
    @discardableResult
    func requestManagerApproval(withPIN pin: String, for capability: POSCapability) async throws(POSAuthError) -> POSStaff {
        // No real PIN gate in this session; return a synthetic approver so callers that key
        // attribution off the result still get a valid POSStaff.
        POSStaff(userID: 0, userLogin: "", displayName: "", role: "", capabilities: [])
    }
    func lock() {}
    func checkLockoutState() throws(POSAuthError) {}
    func refreshPINStatus() async {}
    func clearStaffCache() {}
}
