@MainActor
protocol POSAccessSession: AnyObject {
    var currentStaff: POSStaff? { get }
    var isLocked: Bool { get }
    var pinStatus: POSPINStatus { get }

    func allows(_ capability: POSCapability) -> Bool
    func signIn(withPIN pin: String) async throws(POSAuthError)
    /// Verifies the manager PIN and confirms the approver holds `capability`. Returns the
    /// approver's `POSStaff` so callers can attach `_pos_override_staff_user_id` meta on the
    /// next request.
    @discardableResult
    func requestManagerApproval(withPIN pin: String, for capability: POSCapability) async throws(POSAuthError) -> POSStaff
    func lock()
    func checkLockoutState() throws(POSAuthError)
    func refreshPINStatus() async

    /// Wipes the persisted staff cache for the current site. Called on logout and site-switch
    /// so stale credentials do not survive across sessions.
    func clearStaffCache()
}
