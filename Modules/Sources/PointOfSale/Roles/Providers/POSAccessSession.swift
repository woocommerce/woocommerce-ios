@MainActor
protocol POSAccessSession: AnyObject {
    var currentStaff: POSStaff? { get }
    var isLocked: Bool { get }
    var pinStatus: POSPINStatus { get }

    func allows(_ capability: POSCapability) -> Bool
    func signIn(withPIN pin: String) async throws(POSAuthError)
    func requestManagerApproval(withPIN pin: String, for capability: POSCapability) async throws(POSAuthError)
    func lock()
    func checkLockoutState() throws(POSAuthError)
    func refreshPINStatus() async

    /// Wipes the persisted staff cache for the current site. Called on logout and site-switch
    /// so stale credentials do not survive across sessions.
    func clearStaffCache()
}
